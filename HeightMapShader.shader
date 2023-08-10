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
        
        //heightmap settings
        _Animate ("animate map. 1 true 0 false", int) = 0
        _Scale("scale", float) = 1
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
            #pragma exclude_renderers gles
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
                float3 normal : TEXCOORD1;
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
            int _Animate;
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
                float animation;
                if(_Animate == 1)
                {
                    animation = _Time.y * 500;
                }
                else
                {
                    animation = 0;
                }
                float amplitude = 1;
                float frequency = 1;
                float noiseHeight = 0;
                for(int i = 0; i < _Octaves; i++)
                {
                    float perlinNum = snoise(float2(pos.x / _Scale * frequency, (pos.z + animation) / _Scale * frequency)) * 2 - 1;
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

            float4 CalculateColor(float heightDiff, float height)
            {
                if(height == _lightFilterMin)
                    return _EdgeCol;
                float t = pow(saturate(heightDiff / _SlopeIntensity), _ColorSharpness);
                
                float4 interpolatedColor = lerp(_GroundCol, _CliffCol, t);
                
                return interpolatedColor;
            }
            
            float4x2 getneighborHeights(float4 worldPos, float height)
            {
                float offset = _SlopeOffset;
                float4 heightDiffs;
                float4 heights;

                float bot = PerlinNoise(float4(worldPos.x, worldPos.y, worldPos.z - offset, worldPos.a));
                if(bot <= _lightFilterMin)
                    bot = _lightFilterMin;
                heightDiffs.x = abs(bot - height);
                heights.x = bot;

                float top = PerlinNoise(float4(worldPos.x, worldPos.y, worldPos.z + offset, worldPos.a));
                if(top <= _lightFilterMin)
                    top = _lightFilterMin;
                heightDiffs.y = abs(top - height);
                heights.y = top;

                float right = PerlinNoise(float4(worldPos.x + offset, worldPos.y, worldPos.z, worldPos.a));
                if(right <= _lightFilterMin)
                    right = _lightFilterMin;
                heightDiffs.z = abs(right - height);
                heights.z = right;

                float left = PerlinNoise(float4(worldPos.x - offset, worldPos.y, worldPos.z, worldPos.a));
                if(left <= _lightFilterMin)
                    left = _lightFilterMin;
                heightDiffs.w = abs(left - height);
                heights.w = left;

                return float4x2(heightDiffs, heights);
            }

            float getMaxDiff(float4 heightDiffs)
            {
                float maxDiff = max(max(max(heightDiffs.x, heightDiffs.y), heightDiffs.z), heightDiffs.w);
                return maxDiff;
            }

            //https://forum.unity.com/threads/calculate-vertex-normals-in-shader-from-heightmap.169871/
            float3 computeNormals( float h_A, float h_B, float h_C, float h_D, float h_N, float heightScale )
            {
                //To make it easier we offset the points such that n is "0" height
                float3 va = { 0, 1, (h_A - h_N)*heightScale };
                float3 vb = { 1, 0, (h_B - h_N)*heightScale };
                float3 vc = { 0, -1, (h_C - h_N)*heightScale };
                float3 vd = { -1, 0, (h_D - h_N)*heightScale };
                //cross products of each vector yields the normal of each tri - return the average normal of all 4 tris
                float3 average_n = ( cross(va, vb) + cross(vb, vc) + cross(vc, vd) + cross(vd, va) ) / -4;
                return normalize( average_n );
            }

            float lambertToon(float angle)
            {
                if(step(0.3, angle) == 1)
                {
                    if(step(0.7, angle) == 1)
                        return 0.7;
                    else
                    {
                        return 0.6;
                    }
                }
                else
                {
                    return 0.2;
                }
            }

            v2f vert (appdata v)
            {
                v2f o;

                //calculate new height
                v.worldPos = mul(unity_ObjectToWorld, v.vertex);
                float4 modifiedPos = v.vertex;
                float height = PerlinNoise(v.worldPos);
                if(modifiedPos.y + height <= _lightFilterMin)
                {
                    height = _lightFilterMin;
                    modifiedPos.y += height;
                }
                else
                {
                    modifiedPos.y += height; //modified vertex location
                }
                
                
                //calculating color
                float4x2 neighborSampling = getneighborHeights(v.worldPos, height);
                float4 heightDiff = float4(neighborSampling._11, neighborSampling._21, neighborSampling._31, neighborSampling._41);
                float4 heights = float4(neighborSampling._12, neighborSampling._22, neighborSampling._32, neighborSampling._42);
                float4 calculatedCol = CalculateColor(heightDiff, height);
                
                //calculating normals
                float3 modifiedNormal = computeNormals(heights.y, heights.z, heights.x, heights.w, modifiedPos.y, 10);
                o.normal = modifiedNormal;
                
                //lambertLighting
                float3 normalizedLightDir = _WorldSpaceLightPos0.xyz;
                float lambert = lambertToon(max(0, dot(modifiedNormal, normalizedLightDir)));

                //visualization for adding a proper wave shader later. messing up the shadows 
                if(modifiedPos.y < _lightFilterMin)
                {
                    modifiedPos.y = _lightFilterMin;
                    calculatedCol = _EdgeCol;
                }
                
                o.col = calculatedCol * (1-lambert);
                o.pos = UnityObjectToClipPos(modifiedPos);
                //o.col = float4(normalizedLightDir, 1);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return i.col;
                return float4(i.normal, 1);
            }
            ENDCG
        }
    }
}
