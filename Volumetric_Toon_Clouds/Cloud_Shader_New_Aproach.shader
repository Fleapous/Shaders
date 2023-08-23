Shader "Projects/Unlit/Cloud_Shader_VisualizeClouds"
{
    Properties
    {
        
        _WeatherMap("weatherMap", 2D) = "white" {}
        _ShapeNoise("3D noise map", 3D) = "white" {}
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
                float3 uvw : TEXCOORD1;
                float2 wPos : TEXCOORD2;
                float4 pos : SV_POSITION;
            };

            sampler2D _WeatherMap;
            sampler3D _ShapeNoise;
            float _GlobalCoverage;
            float _GlobalDensity;
            float _HeightPercentage;

            //converts/remaps a value from one range to another
            float ReMap(float v, float lO, float rO, float lN, float rN)
            {
                return lN + ((v - lO) * (rN - lN))/(rO - lO);
            }
            
            //shape altering function
            float ShapeAltering(float maxHeightBlue)
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
            
            float ExtractingWeightedNoise(float4 shapeNoise)
            {
               return ReMap(shapeNoise.r, (shapeNoise.g * 0.625 + shapeNoise.b * 0.25 + shapeNoise.a * 0.125) - 1, 1, 0, 1);
            }
            
            // calculates probability that clouds will appear
            float CloudCoverage(float coverageRed, float coverageGreen)
            {
                return max(coverageRed, saturate(_GlobalCoverage - 0.5) * coverageGreen * 2);
            }

            float MakeClouds(float4 weathermap, float4 shapeNoise)
            {
                float SA = ShapeAltering(weathermap.b);
                float DA = DensityAlteringHeight(weathermap.a);
                float WM = CloudCoverage(weathermap.r, weathermap.g);
                float SNSample = ExtractingWeightedNoise(shapeNoise);

                return saturate(ReMap(SNSample * SA, 1 - _GlobalCoverage * WM, 1, 0, 1)) * DA;
            }
            
            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv = v.vertex.xz;
                o.uvw = v.vertex.xyz;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float2 uv = i.uv;
                float4 weatherData = tex2D(_WeatherMap, uv);
                float4 noise3d = tex3D(_ShapeNoise, i.uvw);
                
                float coverage = CloudCoverage(weatherData.r, weatherData.g);

                // Calculate cloud color based on coverage
                fixed4 cloudColor = float4(coverage, coverage, coverage, coverage);

                return cloudColor;
            }
            ENDCG
        }
    }
}
