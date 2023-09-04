Shader "Projects/Unlit/cloudsSDFv2"
{
    Properties
    {
        _NoiseTexture("NoiseTex", 2D) = "" {}
        _Color("Example color", Color) = (1,1,1,1)
        _LightIntensity("light intensity", Range (0, 1)) = 0
        _UtilitySlider1("slider for debuging", Range(0, 100)) = 1
        _UtilitySlider2("slider for debuging", Range(1, 40)) = 1
    }
    SubShader
    {
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #include "noiseSimplex.cginc"

            #define MAX_DISTANCE 1e+3
            #define MAX_STEPS 100
            #define SURF_DIST 1e-2
            #define SAMPLE_DIST 1
            #define PLANE_SIZE 2

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };
            
            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 rO : TEXCOORD0;
                float3 hitPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            float4 _NoiseTexture_ST;
            sampler2D _NoiseTexture;
            float4 _Color;
            float _LightIntensity;
            int _UtilitySlider1;
            int _UtilitySlider2;

            float rand2dTo1d(float2 value, float2 dotDir = float2(12.9898, 78.233))
            {
                float2 smallValue = sin(value);
                float random = dot(smallValue, dotDir);
                random = frac(sin(random) * 143758.5453);
                return random;
            }

            float SmoothMax(float a, float b, float k)
            {
                return log(exp(k * a) + exp(k * b) / k);
            }
            float SmoothMin(float a, float b, float k)
            {
                return -SmoothMax(-a, -b, k);
            }

            // float SphereSDF(float3 currentPos, float3 spherePos, float r)
            // {
            //     return length(pos) - r;
            // }

            float SpherePerlinSDF(float3 currentPos, float4 spherePos[PLANE_SIZE * PLANE_SIZE], float r, out int index)
            {
                float minDist = 10000000;
                for (int i = 0; i < PLANE_SIZE * PLANE_SIZE; i++)
                {
                    float currentDist = 10000000;
                    if(spherePos[i].w > 0.368)
                    {
                        // float sphereMove = float2(_Time.x * 2, _Time.x * 0);
                        // spherePos[i].xz += sphereMove;
                        currentDist = distance(currentPos, spherePos[i].xyz) - r;
                    }
                    else
                    {
                        currentDist = 10000000; 
                    }
                    if(currentDist <= minDist)
                    {
                        index = i;
                        minDist = currentDist;
                    }
                }
                return minDist;
            }
            
            float GetDist(float3 pos, float4 objectPos)
            {
                return distance(pos, objectPos.xyz) - 5;
            }

            float3 GetNormal(float3 p, float4 objectPos)
            {
                float2 e = float2(1e-1, 0);
                float3 n = GetDist(p, objectPos) - float3(
                    GetDist(float3(p-e.xyy), objectPos),
                    GetDist(float3(p-e.yxy), objectPos),
                    GetDist(float3(p-e.yyx), objectPos)
                );
                return normalize(n);
            }
            
            float RayMarch(float3 rO, float3 rD, float4 spherePos[PLANE_SIZE * PLANE_SIZE], out int index)
            {
                float dO = 0;
                float dS;
                for (int i = 0; i < MAX_STEPS; i++)
                {
                    float3 p = rO + dO * rD;
                    dS = SpherePerlinSDF(p, spherePos, 5, index);
                    dO += dS;
                    if(dS < SURF_DIST || dS > MAX_DISTANCE)
                        break;
                }
                return dO;
            }
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.hitPos = mul(unity_ObjectToWorld, v.vertex); //world space
                o.rO = _WorldSpaceCameraPos; //world space
                o.uv = TRANSFORM_TEX(v.uv, _NoiseTexture);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 rO = i.rO;
                float3 rD = normalize(i.hitPos - rO);
                float4 noiseSamples[PLANE_SIZE * PLANE_SIZE];
                float sizeNormalized = 1.0/PLANE_SIZE;
                int k = 0;

                //return tex2D(_NoiseTexture, i.uv + _Time.y);
                for (int x = 0; x < PLANE_SIZE; x++)
                {
                    for (int z = 0; z < PLANE_SIZE; z++)
                    {
                        float2 uvCords = float2(x, z);
                        //should use a repeatable noise texture
                        float noise = snoise(float2(x, z));
                        float4 noiseTex = tex2D(_NoiseTexture, uvCords);
                        float xCords = fmod(x * _UtilitySlider2 + _Time.y * 4 * rand2dTo1d(uvCords), 300);
                        float zCords = fmod(z * _UtilitySlider2 + _Time.x * 10 * rand2dTo1d(uvCords), 200);
                        noiseSamples[k] = float4( xCords, 0, zCords, noiseTex.r);
                        k++;
                    }
                }

                int index = 0;
                 float d = RayMarch(rO, rD, noiseSamples, index);
                 fixed4 col = 0;
                 if(d < MAX_DISTANCE)
                 {
                     float3 p = rO + rD * d;
                     if(index < 0 || index >= 100)
                         return float4(0,0,0,1);
                     float3 n = GetNormal(p, noiseSamples[index]);
                     float3 lightDir = normalize(_WorldSpaceLightPos0 - p);
                     float lambert = max(0, dot(n, lightDir) + _LightIntensity);
                     
                     col.rgb =_Color.rgb * lambert;
                     //col.rgb = n;
                 }
                 else
                 {
                     discard;
                 }
                return col;
            }
            ENDCG
        }
    }
}
//float s1 = SphereSDF(pos, 2);
//float s2 = SphereSDF(float3(pos.x+_Time.x, pos.yz), 2);
//float smoothMax = SmoothMax(c1, c2, _DebugSlider);
//return SmoothMin(s1, s2, 1);
//return SpherePerlinSDF(pos, 2);
//return SpherePerlinSDF(pos, spherePos, 5);
