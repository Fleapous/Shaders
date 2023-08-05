Shader "HeightMap/HeightMapShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MaxCol ("MaxColor", Color) = (1, 1, 1, 1)
        _MinCol ("MinColor", Color) = (1, 1, 1, 1)
        _Scale("scale", Range(0.001, 1000)) = 1
        _SlopeIntensity("SlopeIntensity", Range(0.1, 10)) = 1
        _HeightScalar("HeightScalar", Range(0.1, 100)) = 1
        _Lacunarity("Lacunarity", Range(0.01, 10)) = 1
        _Persistence("persistence", Range(0.01, 10)) = 1
        _Octaves("Octaves", Range(1, 10)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "noiseSimplex.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 uv: TEXCOORD0;
                float4 texcoord1: TEXCOORD1;
                float4 texcoord2: TEXCOORD2;
                float4 worldPos : TEXCOORD3;
                float4 col : COLOR;
            };
            
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD1; // Pass the modified normal to fragment shader
                float3 worldPos : TEXCOORD2; // Pass the world position to fragment shader
                float4 col : COLOR;
            };

            sampler2D _MainTex;
            float4 _MaxCol;
            float4 _MinCol;
            float4 _MainTex_ST;
            float _Scale;
            float _SlopeIntensity;
            float _HeightScalar;
            float _Lacunarity;
            float _Persistence;
            float _Octaves;

            float sinMap(float4 pos)
            {
                return sin(pos.x);
            }

            float PerlinNoise(float4 pos)
            {
                //float noise = (snoise(float2(pos.x * scale, pos.z * scale)) * 2) - 1;
                float amplitude = 1;
                float frequency = 1;
                float noiseHeight = 0;
                for(int i = 0; i < _Octaves; i++)
                {
                    float perlinNum = snoise(float2(pos.x / _Scale * frequency, pos.z / _Scale * frequency)) * 2 - 1;
                    noiseHeight += perlinNum * amplitude;
                    amplitude *= _Persistence;
                    frequency *= _Lacunarity;
                }
                return noiseHeight; 
            }

            float CalculateSlope(float3 normal)
            {
                float dotProd = dot(normal, float3(0, 1, 0));
                return acos(dotProd);
            }

            v2f vert (appdata v)
            {
                v2f o;
                v.worldPos = mul(unity_ObjectToWorld, v.vertex);
                float height = PerlinNoise(v.worldPos);
                v.vertex.y += height;

                //recalculate normal  after changing the hieght
                v.normal = normalize(float3(v.normal.x + height, v.normal.y, v.normal.z));

                //transforming from object to clip space
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                
                o.normal = UnityObjectToWorldNormal(v.normal); // Convert to world space normal
                o.worldPos = v.worldPos; // Pass the world position
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Calculate Lambertian lighting
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
                float lambert = max(0, dot(i.normal, lightDir));
                
                float angle = CalculateSlope(i.normal);
                angle *= _SlopeIntensity;
                float3 color = lerp(_MaxCol.rgb, _MinCol.rgb, angle/3.14159);
                return float4(color, 1) * lambert;
            }
            ENDCG
        }
    }
}
