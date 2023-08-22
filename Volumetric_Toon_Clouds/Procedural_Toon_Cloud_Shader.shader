Shader "Projects/Unlit/Procedural_Toon_Cloud_Shader"
{
    Properties
    {
        _MinNoiseLim("noise value for cloud render", Range(0,1)) = 0.5
        _NoiseScale("scale of the noise", float) = 1
    }
    SubShader
    {
        Tags {"Queue"="Transparent"}
        Blend SrcAlpha OneMinusSrcAlpha
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #include "noiseSimplex.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };
            
            struct v2f
            {
                float3 Wpos : TEXCOORD0;
                float4 pos : SV_POSITION;
            };
            
            #define STEPS 200
            #define STEP_SIZE 0.01

            float _MinNoiseLim;
            float _NoiseScale;

            float GenerateNoise(float3 pos)
            {
                return snoise(float3(pos.x / _NoiseScale, pos.y / _NoiseScale, pos.z / _NoiseScale));
            }
            
            bool SphereHit(float3 pos)
            {
                float noiseValue = GenerateNoise(pos);
                if(noiseValue >= _MinNoiseLim)
                    return true;
                else
                {
                    return false;
                }
            }

            float3 RayMarch(float3 pos, float3 dir)
            {
                for(int i = 0; i < STEPS; i++)
                {
                    if(SphereHit(pos))
                        return pos;
                    pos += dir * STEP_SIZE;
                }
                return 0;
            }
            
            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.Wpos = mul(unity_ObjectToWorld, v.vertex).xyz;
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 viewDir = normalize(i.Wpos - _WorldSpaceCameraPos);
                float3 depth = RayMarch(i.Wpos, viewDir);
                if(length(depth) != 0)
                    return float4(1,0,0,1);
                else
                {
                    return float4(1,1,1,0);
                }
                
            }
            ENDCG
        }
    }
}
