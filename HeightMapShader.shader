Shader "HeightMap/HeightMapShader"
{
    Properties
    {
        //height map colors
        _GroundCol ("Ground color", Color) = (1, 1, 1, 1)
        _EdgeCol ("Edge Color", Color) = (1, 1, 1, 1)
        _CliffCol("cliff color", Color) = (1,1,1,1)
        
        //lighting settings
        _LightCol ("light color", Color) = (1, 1, 1, 1)
        _SlopeOffset("slope offset", Range(0, 1)) = 0
        _SlopeIntensity("SlopeIntensity", Range(0, 100)) = 1
        _lightFilterMax("lightFilterMax", float) = 1
        _lightFilterMin("lightFilterMin", float) = 1
        
        //heightmap settins
        _Scale("scale", Range(0.001, 1000)) = 1
        _HeightScalar("HeightScalar", Range(0.01, 100)) = 1
        _Lacunarity("Lacunarity", Range(0.01, 10)) = 1
        _Persistence("persistence", Range(0.01, 10)) = 1
        _Octaves("Octaves", Range(1, 10)) = 1
    }
    SubShader
    {
        Tags {"LightMode" = "ForwardBase"}

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
            };
            
            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 normal : TEXCOORD1; // Pass the modified normal to fragment shader
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
            float4 _LightCol;

            uniform float4 _LightColor0;

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
                return noiseHeight * _HeightScalar; 
            }

            float CalculateSlope(float3 normal)
            {
                float dotProd = dot(normal, float3(0, 1, 0));
                return acos(dotProd) / 3.14159;
            }

            float4 CalculateColor(float heightDiff)
            {
                if(heightDiff > _SlopeIntensity)
                    return _CliffCol;
                return _GroundCol;
            }


            // float LambertToon(float3 lightDir, float normal)
            // {
            //     
            //     float lambertToon = max(0,dot(normal, lightDir));
            //     //return lambertToon;
            //     if(lambertToon > _lightFilterMax)
            //         return 0.2;
            //     if(lambertToon < _lightFilterMin)
            //         return 0.8;
            //     return 1;
            // }

            float getneighborHeights(float4 worldPos, float height)
            {
                float offset = _SlopeOffset;
                float maxDiff = -1e20;  // Initialize to a very small value
                
                float bot = PerlinNoise(float4(worldPos.x, worldPos.y, worldPos.z - offset, worldPos.a));
                float diff = abs(bot - height);
                if (diff > maxDiff)
                    maxDiff = diff;
                
                float top = PerlinNoise(float4(worldPos.x, worldPos.y, worldPos.z + offset, worldPos.a));
                diff = abs(top - height);
                if (diff > maxDiff)
                    maxDiff = diff;
                
                float right = PerlinNoise(float4(worldPos.x + offset, worldPos.y, worldPos.z, worldPos.a));
                diff = abs(right - height);
                if (diff > maxDiff)
                    maxDiff = diff;
                
                float left = PerlinNoise(float4(worldPos.x - offset, worldPos.y, worldPos.z, worldPos.a));
                diff = abs(left - height);
                if (diff > maxDiff)
                    maxDiff = diff;
                
                return maxDiff;
            }


            v2f vert (appdata v)
            {
                v2f o;

                //calculate new height
                v.worldPos = mul(unity_ObjectToWorld, v.vertex);
                float4 modifiedPos = v.vertex;
                float height = PerlinNoise(v.worldPos);
                float4 heightDiff = getneighborHeights(v.worldPos, height);
                modifiedPos.y += height;
                o.col = CalculateColor(heightDiff);
                float3 modifiedNormal = normalize(float3(v.normal.x, v.normal.y + height, v.normal.z));
                o.normal = modifiedNormal;
                
                o.pos = UnityObjectToClipPos(modifiedPos);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return i.col;
            }
            ENDCG
        }
    }
}
