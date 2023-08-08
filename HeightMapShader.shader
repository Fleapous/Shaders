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
        _SlopeIntensity("SlopeIntensity", Range(0, 1)) = 1
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
                float4 col : COLOR;
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
                return noiseHeight; 
            }

            float CalculateSlope(float3 normal)
            {
                float dotProd = dot(normal, float3(0, 1, 0));
                return acos(dotProd) / 3.14159;
            }

            float4 CalculateColor(float deg)
            {
                // Calculate a factor that blends between edge and cliff colors
                float blendFactor = smoothstep(_SlopeIntensity, _SlopeIntensity + _SlopeOffset, deg);

                // Interpolate between ground color and edge color based on blend factor
                float4 groundToEdge = lerp(_GroundCol, _EdgeCol, blendFactor);

                // Interpolate between edge color and cliff color based on blend factor
                float4 edgeToCliff = lerp(_EdgeCol, _CliffCol, blendFactor);

                // Final color interpolation between ground color and cliff color based on blend factor
                return lerp(groundToEdge, edgeToCliff, blendFactor);
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
                // v2f o;
                //
                // v.worldPos = mul(unity_ObjectToWorld, v.vertex);
                // float height = PerlinNoise(v.worldPos) * _HeightScalar;
                // v.vertex.y += height;
                //
                // // v.worldPos = mul(unity_ObjectToWorld, v.vertex);
                // // float3 newHeight = v.vertex;
                // // newHeight.y += PerlinNoise(v.worldPos) * _HeightScalar;
                // //
                // //
                // // //calculating normals
                // // float3 tangent = float3(1,0,0);
                // // float3 posPlusTan = v.vertex + tangent * 0.001;
                // // posPlusTan += PerlinNoise(v.worldPos) * _HeightScalar;
                // //
                // // float3 biTan = cross(v.normal, tangent);
                // // float3 posBiTan = v.vertex + biTan * 0.001;
                // // posBiTan += PerlinNoise(v.worldPos) * _HeightScalar;
                // //
                // // float3 modifiedTan = posPlusTan - newHeight;
                // // float3 modifiedBiTan = posBiTan - newHeight;
                // //
                // // float3 modifiedNormal = cross(modifiedTan, modifiedBiTan);
                // // v.normal = normalize(modifiedNormal);
                // // v.vertex.xyz = newHeight;
                //
                // //recalculate normal  after changing the hieght
                // //v.normal = normalize(float3(v.normal.x + height * _HeightScalar, v.normal.y, v.normal.z));
                //
                // //lambert
                // float3 normalDir = normalize(mul(float4(v.normal, 0.0), unity_WorldToObject).xyz);
                // float3 modifiedNormal = normalize(v.normal + normalDir * height);
                // float3 lightDir;
                // float atten = 1;
                // lightDir = normalize(_WorldSpaceLightPos0.xyz);
                // float3 diffuseReflection = atten *_LightColor0.xyz*_LightCol.rgb*max(0.0,dot(normalDir, lightDir));
                // o.col = float4(diffuseReflection, 1.0);
                //
                // //calculate color
                // float angle = CalculateColor(modifiedNormal);
                // o.col = CalculateColor(angle);
                // o.col *= float4(diffuseReflection, 1.0);
                //
                // o.pos = UnityObjectToClipPos(v.vertex);
                // o.normal = normalDir;
                // //o.normal = UnityObjectToWorldNormal(modifiedNormal); // Convert to world space normal
                // return o;


                v2f o;

                //calculate new height
                v.worldPos = mul(unity_ObjectToWorld, v.vertex);
                float height = PerlinNoise(v.worldPos) * _HeightScalar;
                height += 300;
                v.vertex.x += height;
                if (v.vertex.y < 1)
                {
                    o.col = float4(1,0,0,1);
                }
                else
                    o.col = float4(0,1,0,1);
                
                //recalculate normals
                //calculating normals
                float3 tangent = float3(1,0,0);
                float3 posPlusTan = abs(v.vertex) + tangent * 2.0;
                posPlusTan += PerlinNoise(v.worldPos) * _HeightScalar;
                
                float3 biTan = cross(v.normal, tangent);
                float3 posBiTan = abs(v.vertex) + biTan * 2.0;
                posBiTan += PerlinNoise(v.worldPos) * _HeightScalar;
                
                float3 modifiedTan = posPlusTan - height;
                float3 modifiedBiTan = posBiTan - height;
                
                float3 modifiedNormal = cross(modifiedTan, modifiedBiTan);
                v.normal = modifiedNormal;
                o.normal = v.normal;
                //y axis line 
                // v.normal = normalize(float3(v.normal.x, v.normal.y + height, v.normal.z));
                // o.normal = v.normal;
                
                o.pos = UnityObjectToClipPos(v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //return i.col;
                return float4(i.normal, 1);
                return i.col;
            }
            ENDCG
        }
    }
}
