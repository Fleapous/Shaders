Shader "HeightMap/HeightMapShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _GroundCol ("Ground color", Color) = (1, 1, 1, 1)
        _EdgeCol ("Edge Color", Color) = (1, 1, 1, 1)
        _CliffCol("cliff color", Color) = (1,1,1,1)
        _Scale("scale", Range(0.001, 1000)) = 1
        _SlopeOffset("slope offset", Range(0, 1)) = 0
        _SlopeIntensity("SlopeIntensity", Range(0, 1)) = 1
        _lightFilterMax("lightFilterMax", float) = 1
        _lightFilterMin("lightFilterMin", float) = 1
        _HeightScalar("HeightScalar", Range(0.01, 100)) = 1
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
            float4 _GroundCol;
            float4 _EdgeCol;
            float4 _CliffCol;
            float _SlopeOffset;
            float _lightFilterMax;
            float _lightFilterMin;
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
                return acos(dotProd) / 3.14159;
            }

            float4 CalculateColor(float deg)
            {
                if(deg > _SlopeIntensity + _SlopeOffset)
                        return _GroundCol;
                if(deg > _SlopeIntensity)
                    return _EdgeCol;
                return _CliffCol;
            }

            float LambertToon(float3 lightDir, float normal)
            {
                
                float lambertToon = max(0,dot(normal, lightDir));
                //return lambertToon;
                if(lambertToon > _lightFilterMax)
                    return 0.2;
                if(lambertToon < _lightFilterMin)
                    return 0.8;
                return 1;
            }

            v2f vert (appdata v)
            {
                v2f o;
                v.worldPos = mul(unity_ObjectToWorld, v.vertex);
                float height = PerlinNoise(v.worldPos);
                v.vertex.y += height * _HeightScalar;

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
                float angle = CalculateSlope(i.normal);
                return float4(CalculateColor(angle).rgb, 1) * LambertToon(lightDir, i.normal);
            }
            ENDCG
        }
    }
}
