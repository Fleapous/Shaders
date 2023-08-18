Shader "Unlit/CloudShader"
{
    Properties
    {
        _StepSize("step size", float) = 1
        _Steps("steps", float) = 1
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

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float3 viewDir : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float _StepSize;
            float _Steps;

            float SDFSphere(float3 position, float3 centre, float radius)
            {
                return length(position - centre) - radius;
            }
            
            float3 RayMarch(float3 position, float3 viewDir)
            {
                for (int i = 0; i < _Steps; i++)
                {
                    float distanceToSphere = SDFSphere(position, float3(0, 0, 0), 0.5);
                    if (distanceToSphere < 0.001)
                    {
                        return float3(1, 1, 1);
                    }
                    position += viewDir * _StepSize;
                }
                return float3(0, 0, 0);
            }


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.viewDir = normalize(_WorldSpaceCameraPos.xyz - v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 raymarch = RayMarch(i.vertex, i.viewDir);
                return float4(raymarch, 1);
            }

            ENDCG
        }
    }
}
