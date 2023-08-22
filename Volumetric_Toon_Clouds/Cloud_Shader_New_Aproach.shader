Shader "Projects/Unlit/Cloud_Shader_VisualizeClouds"
{
    Properties
    {
        
        _WeatherMap("weatherMap", 2D) = "white" {}
        _GlobalCoverage("global cloud coverage", Range(0, 1)) = 0
        _GlobalDensity("global cloud density", Range(0, 1000)) = 0
        
        _HeightPercentage("height percentage", Range(0, 1)) = 0
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

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float2 wPos : TEXCOORD1;
                float4 pos : SV_POSITION;
            };

            sampler2D _WeatherMap;
            float _GlobalCoverage;
            float _GlobalDensity;
            float _HeightPercentage;

            //converts/remaps a value from one range to another
            float ReMap(float v, float lO, float rO, float lN, float rN)
            {
                return lN + ((v - lO) * (rN - lN))/(rO - lO);
            }
            
            //shape altering function
            float shapeAltering(float maxHeightBlue)
            {
                float shapeAlterBot = saturate(ReMap(_HeightPercentage, 0, 0.07, 0, 1));
                float shapeAlterTop = saturate(ReMap(_HeightPercentage, maxHeightBlue * 0.2, maxHeightBlue, 1, 0));
                
                return shapeAlterBot * shapeAlterTop;
            }

            //density altering function dependent on height
            float DensityAlteringHeight(float weathermapAlpha)
            {
                float densityAlterBottom = _HeightPercentage * saturate(ReMap(_HeightPercentage, 0, 0.15, 0, 1));
                float densityAlterTop = saturate(ReMap(_HeightPercentage, 0.9, 1.0, 1, 0));

                return _GlobalDensity * densityAlterBottom * densityAlterTop * weathermapAlpha * 2;
            }

            // calculates probability that clouds will appear
            float CloudCoverage(float coverageRed, float coverageGreen)
            {
                return max(coverageRed, saturate(_GlobalCoverage - 0.5) * coverageGreen * 2);
            }
            
            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv = v.vertex.xz;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float2 uv = i.uv; // Assuming clouds are centered around the origin
                float4 weatherData = tex2D(_WeatherMap, uv);
                float coverage = CloudCoverage(weatherData.r, weatherData.g);

                // Calculate cloud color based on coverage
                fixed4 cloudColor = float4(coverage, coverage, coverage, coverage);

                return cloudColor;
            }
            ENDCG
        }
    }
}
