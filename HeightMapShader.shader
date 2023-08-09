Shader "HeightMap/HeightMapShader"
{
    Properties
    {
        //height map colors
        _GroundCol ("Ground color", Color) = (1, 1, 1, 1)
        _EdgeCol ("Edge Color", Color) = (1, 1, 1, 1)
        _CliffCol("cliff color", Color) = (1,1,1,1)
        _SlopeOffset("slope offset", Range(0, 1)) = 0
        _SlopeIntensity("SlopeIntensity", Range(0, 100)) = 1
        _ColorSharpness("color transition sharpness", Range(0.01, 100)) = 1
        
        //lighting settings
        _LightCol ("light color", Color) = (1, 1, 1, 1)
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
            float _ColorSharpness;
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
                return noiseHeight * _HeightScalar + 600; 
            }

            float CalculateSlope(float3 normal)
            {
                float dotProd = dot(normal, float3(0, 1, 0));
                return acos(dotProd) / 3.14159;
            }

            float4 CalculateColor(float heightDiff)
            {
                float t = pow(saturate(heightDiff / _SlopeIntensity), _ColorSharpness);
                
                float4 interpolatedColor = lerp(_GroundCol, _CliffCol, t);
                
                return interpolatedColor;
            }
            
            float4 getneighborHeights(float4 worldPos, float height)
            {
                float offset = _SlopeOffset;
                float4 heightDiffs;

                float bot = PerlinNoise(float4(worldPos.x, worldPos.y, worldPos.z - offset, worldPos.a));
                heightDiffs.x = abs(bot - height);

                float top = PerlinNoise(float4(worldPos.x, worldPos.y, worldPos.z + offset, worldPos.a));
                heightDiffs.y = abs(top - height);

                float right = PerlinNoise(float4(worldPos.x + offset, worldPos.y, worldPos.z, worldPos.a));
                heightDiffs.z = abs(right - height);

                float left = PerlinNoise(float4(worldPos.x - offset, worldPos.y, worldPos.z, worldPos.a));
                heightDiffs.w = abs(left - height);

                return heightDiffs;
            }

            float getMaxDiff(float4 heightDiffs)
            {
                float maxDiff = max(max(max(heightDiffs.x, heightDiffs.y), heightDiffs.z), heightDiffs.w);
                return maxDiff;
            }


            float3 getNormal(float3 normal, float4 vertex, float height, float4 heightDiff)
            {
                // Calculate normal for the modified position
                float3 modifiedNormal = normalize(float3(normal.x, normal.y + height, normal.z));
                
                // Calculate neighboring heights and normals
                float3 botPos = vertex - float4(0, heightDiff.x, 0, 0);
                float3 topPos = vertex + float4(0, heightDiff.y, 0, 0);
                float3 rightPos = vertex + float4(heightDiff.z, 0, 0, 0);
                float3 leftPos = vertex - float4(heightDiff.w, 0, 0, 0);
                
                float3 botNormal = normalize(float3(normal.x, normal.y + PerlinNoise(float4(botPos.x, botPos.y, botPos.z, 0)), normal.z));
                float3 topNormal = normalize(float3(normal.x, normal.y + PerlinNoise(float4(topPos.x, topPos.y, topPos.z, 0)), normal.z));
                float3 rightNormal = normalize(float3(normal.x + PerlinNoise(float4(rightPos.x, rightPos.y, rightPos.z, 0)), normal.y, normal.z));
                float3 leftNormal = normalize(float3(normal.x + PerlinNoise(float4(leftPos.x, leftPos.y, leftPos.z, 0)), normal.y, normal.z));
                
                // Interpolate normals based on height differences
                float tBot = pow(saturate(heightDiff.x / _SlopeIntensity), _ColorSharpness);
                float tTop = pow(saturate(heightDiff.y / _SlopeIntensity), _ColorSharpness);
                float tRight = pow(saturate(heightDiff.z / _SlopeIntensity), _ColorSharpness);
                float tLeft = pow(saturate(heightDiff.w / _SlopeIntensity), _ColorSharpness);
                
                float3 interpolatedNormal = normalize(
                    lerp(modifiedNormal, botNormal, tBot) +
                    lerp(modifiedNormal, topNormal, tTop) +
                    lerp(modifiedNormal, rightNormal, tRight) +
                    lerp(modifiedNormal, leftNormal, tLeft)
                );
                return  interpolatedNormal;
            }

            v2f vert (appdata v)
            {
                v2f o;

                //calculate new height
                v.worldPos = mul(unity_ObjectToWorld, v.vertex);
                float4 modifiedPos = v.vertex;
                float height = PerlinNoise(v.worldPos);
                modifiedPos.y += height; //modified vertex location
                
                //calculating color
                float4 heightDiff = getneighborHeights(v.worldPos, height); //find the highest diff amongst neighboring heights
                float4 calculatedCol = CalculateColor(getMaxDiff(heightDiff));
                
                //calculating normals
                float3 modifiedNormal = getNormal(v.normal, v.vertex, height, heightDiff);
                o.normal = modifiedNormal;

                //lambertLighting
                float3 lightDir = _WorldSpaceLightPos0.xyz - v.worldPos.xyz;
                float3 normalizedLightDir = normalize(lightDir);
                float lambert = max(0, dot(modifiedNormal, normalizedLightDir));
                o.col.rgb = calculatedCol * (1-lambert);
                
                o.pos = UnityObjectToClipPos(modifiedPos);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return i.col;
                //return float4(i.normal, 1);
            }
            ENDCG
        }
    }
}
