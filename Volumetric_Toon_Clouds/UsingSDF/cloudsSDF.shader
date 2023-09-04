Shader "Projects/Unlit/cloudsSDF"
{
    Properties
    {
        _Color("Example color", Color) = (1,1,1,1)
        _LightIntensity("light intensity", Range (0, 1)) = 0
        
        _CloudDistanceY("clouds Y distance from eachother", Range(0.1, 1000)) = 1
        _CloudDistanceZ("clouds Z distance from eachother", Range(0.1, 1000)) = 1

        _CloudParticuleDistance("cloud particule distance", Range(0.1, 10)) = 1
        _CloudParticuleSize("cloud particule size", Range(0.1, 10)) = 1
        
        _UtilitySlider1("slider for debuging", float) = 1
        _UtilitySlider2("slider for debuging", float) = 1
    }
    SubShader
    {
        
        Pass
        {
            CGPROGRAM
            // Upgrade NOTE: excluded shader from DX11, OpenGL ES 2.0 because it uses unsized arrays
            #pragma exclude_renderers d3d11 gles
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #include "noiseSimplex.cginc"

            #define MAX_DISTANCE 1e+4
            #define MAX_STEPS 100
            #define SURF_DIST 1e-1

            #define CLOUD_NUMBER 20
            #define CLOUD_PARTICULES 6

            struct appdata
            {
                float4 vertex : POSITION;
            };
            
            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 rO : TEXCOORD0;
                float3 hitPos : TEXCOORD1;
            };

            float4 _Color;
            float _CloudDistanceY;
            float _CloudDistanceZ;
            float _CloudParticuleDistance;
            float _CloudParticuleSize;
            float _LightIntensity;
            float _UtilitySlider1;
            float _UtilitySlider2;

            float rand2dTo1d(float2 value, float2 dotDir = float2(12.9898, 78.233))
            {
                float2 smallValue = sin(value);
                float random = dot(smallValue, dotDir);
                random = frac(sin(random) * 143758.5453);
                return random;
            }

            float rand1dTo1d(float3 value, float mutator = 0.546)
            {
	            float random = frac(sin(value + mutator) * 143758.5453);
	            return random;
            }

            float3 rand1dTo3d(float value){
                return float3(
                    rand1dTo1d(value, 3.9812),
                    rand1dTo1d(value, 7.1536),
                    rand1dTo1d(value, 5.7241)
                );
            }


            float SmoothMax(float a, float b, float k)
            {
                return log(exp(k * a) + exp(k * b) / k);
            }
            float SmoothMin(float a, float b, float k)
            {
                return -SmoothMax(-a, -b, k);
            }

            float sdEllipsoid(float3 p, float3 r)
            {
                float k0 = length(p/r);
                float k1 = length(p/(r*r));
                return k0*(k0-1.0)/k1;
            }

            float SphereSDF(float3 pos, float r)
            {
                return length(pos) - r;
            }

            float CLoudSDF(float3 pos, float seed)
            {
                float shortestDist = 1e+10;
                
                for (int i = 0; i < CLOUD_PARTICULES; i++)
                {
                    
                    float3 randomOffset = rand1dTo3d(i * seed * 1000) * _CloudParticuleDistance; // Generate a random offset
                    float randomRadius = rand1dTo3d(i * seed * 1000) * _CloudParticuleSize; // Generate a random radius
                    
                    float3 modifiedPos = pos + randomOffset * 3;
                    
                    float distance = SphereSDF(modifiedPos, randomRadius);
                    shortestDist = SmoothMin(shortestDist, distance, 0.96);
                }
                
                return shortestDist;
            }


            float CalculateCloud(float seed, float3 pos, float r)
            {
                //float3 cloudPos = pos + _CloudDistance * rand1dTo3d(seed);
                float3 cloudPos = float3(pos.x, pos.y + _CloudDistanceY * rand1dTo1d(seed * 23), pos.z + _CloudDistanceZ * rand1dTo1d(seed * 43));
                float time = _Time.x; //for debug remove later

                float cloudSpeedX = 1 + rand1dTo1d(seed) * (10 - 1);
                float loopOffsetX = fmod(time * cloudSpeedX, 60) * 10; // 5 determines the loop radius 
                cloudPos.x += loopOffsetX;

                float randNmbY = rand1dTo1d(seed * 2);
                float directionY = 1;
                if(fmod(round(randNmbY *20), 2) == 0)
                    directionY = -1;
                float cloudSpeedY = 0.2 + randNmbY * (0.5 - 0.2);
                float loopOffsetY = sin(time * cloudSpeedY) * 5 * directionY;
                cloudPos.y += loopOffsetY;
                
                float randNmbZ = rand1dTo1d(seed * 2);
                float directionZ = 1;
                if(fmod(round(randNmbZ *20), 2) == 0)
                    directionZ = -1;
                float cloudSpeedZ = 1 + rand1dTo1d(seed * 10) * (3 - 1);
                float loopOffsetZ = sin(time * cloudSpeedZ) * 5 * directionZ;
                cloudPos.z += loopOffsetZ; 

                //float distance = SphereSDF(cloudPos, rand1dTo1d(max(r, r + rand1dTo1d(seed * 100) * 2)));
                //float distance = sdEllipsoid(cloudPos, float3(40, 15, 30));
                float distance = CLoudSDF(cloudPos, seed);
                
                return distance;
            }

            float CLouds(float3 pos, float r)
            {
                float shortestDist = 1e+10;
                for (int i = 0; i < CLOUD_NUMBER; i++)
                {
                    
                    float distance = CalculateCloud(i, pos, r);
                    shortestDist = SmoothMin(shortestDist, distance, 1);
                    //shortestDist = min(shortestDist, distance);
                }
                return shortestDist;
            }
            
            float GetDist(float3 pos)
            {
                return CLouds(pos, 10);
            }

            float3 GetNormalFiniteDiff(float3 p)
            {
                float e = 1e-2;
                float center = GetDist(p);
                float xDist = GetDist(p + float3(e,0,0));
                float yDist = GetDist(p + float3(0,e,0));
                float zDist = GetDist(p + float3(0,0,e));
                return (float3(xDist, yDist, zDist)-center) / e;
            }
            
            float RayMarch(float3 rO, float3 rD)
            {
                float dO = 0;
                float dS;
                for (int i = 0; i < MAX_STEPS; i++)
                {
                    float3 p = rO + dO * rD;
                    dS = GetDist(p);
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
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 rO = i.rO;
                float3 rD = normalize(i.hitPos - rO);
                
                float d = RayMarch(rO, rD);
                fixed4 col = 0;
                if(d < MAX_DISTANCE)
                {
                    float3 p = rO + rD * d;
                    //float shading = softshadow(p, normalize(_WorldSpaceLightPos0 - p), _UtilitySlider1, 100, _UtilitySlider2);
                    //col.rgb = shading;
                    // float3 n = GetNormal(p);
                    // float3 lightDir = normalize(_WorldSpaceLightPos0 - p);
                    // float lambert = max(0, dot(n, lightDir) + _LightIntensity);
                    //col.rgb = _Color.rgb * lambert;

                    //col.rgb = n;

                    float normal = GetNormalFiniteDiff(p);
                    float3 lightDir = normalize(_WorldSpaceLightPos0 - p);
                    float lambert = max(0.3, dot(normal, lightDir) + _LightIntensity);
                    col.rgb = _Color.rgb * lambert;
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

            // float3 GetNormal(float3 p)
            // {
            //     float2 e = float2(1e-2, 0);
            //     float3 n = GetDist(p) - float3(
            //         GetDist(p-e.xyy),
            //         GetDist(p-e.yxy),
            //         GetDist(p-e.yyx)
            //     );
            //     return normalize(n);
            // }


         // float softshadow( in float3 ro, in float3 rd, float mint, float maxt, float k )
            // {
            //     float res = 1.0;
            //     float t = mint;
            //     for( int i=0; i<256 && t<maxt; i++ )
            //     {
            //         float h = GetDist(ro + rd*t);
            //         if( h<0.001 )
            //             return 0.3;
            //         res = min( res, k*h/t );
            //         t += h;
            //     }
            //     return res;
            // }
