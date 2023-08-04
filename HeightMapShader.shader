Shader "HeightMap/HeightMapShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Scale("scale", Range(0.001, 1000)) = 1
        _MaxHeight("maxHeight", Range(0, 1000)) = 1
        _MinHeight("MinHeight", Range(0, 1000)) = 1
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
            };
            
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD1; // Pass the modified normal to fragment shader
                float3 worldPos : TEXCOORD2; // Pass the world position to fragment shader
                float vertexHeight : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Scale;
            float _MaxHeight;
            float _MinHeight;

            float sinMap(float4 pos)
            {
                return sin(pos.x);
            }

            float PerlinNoise(float4 pos, float scale)
            {
                float noise = snoise(float2(pos.x * scale, pos.z * scale));
                return (noise + 1)/2;
            }

            v2f vert (appdata v)
            {
                v2f o;
                v.worldPos = mul(unity_ObjectToWorld, v.vertex);
                _Scale = 1/_Scale;
                float height = PerlinNoise(v.worldPos, _Scale);
                v.vertex.y += height;

                //recalculate normal  after changing the hieght
                v.normal = normalize(float3(v.normal.x + height, v.normal.y, v.normal.z));

                //transforming from object to clip space
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                
                o.normal = UnityObjectToWorldNormal(v.normal); // Convert to world space normal
                o.worldPos = v.worldPos; // Pass the world position
                o.vertexHeight = v.vertex.y;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float remappedHeight = (i.vertexHeight - _MinHeight) / (_MaxHeight - _MinHeight); 
                fixed4 remappedUV = tex2D(_MainTex, float2(remappedHeight, 0)); // Use remappedHeight as U-coordinate
                
                // Calculate Lambertian lighting
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
                float lambert = max(0, dot(i.normal, lightDir));

                // Sample the texture
                // fixed4 texColor = tex2D(_MainTex, i.uv);

                // Combine Lambertian lighting with texture color
                fixed4 finalColor = remappedUV;

                fixed4 tmp = tex2D(_MainTex, i.uv);
                return tmp;
            }
            ENDCG
        }
    }
}
