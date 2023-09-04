Shader "Unlit/3dTextureRayMarchTest"
{
    Properties {
        _MainTex3D ("3D Texture", 3D) = "white" {}
        _RayMarchDebug("debugs the steps", Range(0, 1000)) = 0
    }

    SubShader {
        Tags { "Queue" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            #define MAX_STEPS 1000
            #define MAX_DIST 100
            #define STEP_SIZE 1e-1

            struct appdata_t {
                float4 vertex : POSITION;
                float4 uvw : TEXCOORD0;
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float3 ro : TEXCOORD0;
                float4 hitPos : TEXCOORD1;
                float4 uvw : TEXCOORD2;
            };

            sampler3D _MainTex3D;
            float _RayMarchDebug;

            float4 RayMarch(float3 rO, float3 rD)
            {
                float density = 0.0;
                for (int i = 0; i < MAX_STEPS; i++)
                {
                    float3 currentPos = rO + i * STEP_SIZE * rD;
                    float noiseValue;

                    // Check if the current position is outside the texture bounds
                    if (currentPos.x > 1.0 || currentPos.y > 1.0 || currentPos.z > 1.0 ||
                        currentPos.x < 0.0 || currentPos.y < 0.0 || currentPos.z < 0.0)
                    {
                        noiseValue = 0;
                    }
                    else
                    {
                        // Sample the 3D texture
                        noiseValue = tex3D(_MainTex3D, currentPos);
                    }

                    density += noiseValue;
                }
                return density;
            }

            v2f vert(appdata_t v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.hitPos = mul(unity_ObjectToWorld, v.vertex); //world space
                o.ro = _WorldSpaceCameraPos; //world space
                o.uvw = v.uvw;
                return o;
            }

            half4 frag(v2f i) : SV_Target {
                // Sample the 3D texture at the object's position
                float3 rO = i.ro;
                float3 rD = normalize(i.hitPos - rO);
                
                float4 density = RayMarch(rO, rD);
                float4 texturet = tex3D(_MainTex3D, rO + _RayMarchDebug * STEP_SIZE * rD);
                
                return float4(1, 1, 1, density.a * 3);
            }
            ENDCG
        }
    }
}
