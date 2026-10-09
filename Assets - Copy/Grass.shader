Shader "Unlit/Grass"
{
    Properties
    {
        _GrassColor ("Main Grass Color", Color) = (0.15, 0.4, 0.12, 1)
        _LightGrass ("Light Grass", Color) = (0.3, 0.55, 0.18, 1)
        _DarkGrass ("Dark Grass", Color) = (0.06, 0.22, 0.07, 1)
        _GrassDensity ("Grass Density", Range(2, 40)) = 18
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
            "Queue" = "Geometry"
        }

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                half4 _GrassColor;
                half4 _LightGrass;
                half4 _DarkGrass;
                float _GrassDensity;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                OUT.positionHCS =
                    TransformObjectToHClip(IN.positionOS.xyz);

                OUT.uv = IN.uv;

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float2 gridUV = IN.uv * _GrassDensity;

                float2 cell = frac(gridUV);
                float2 cellID = floor(gridUV);

                float randomValue =
                    frac(sin(dot(cellID, float2(12.9898, 78.233)))
                    * 43758.5453);

                float bladeX = 0.25 + randomValue * 0.5;

                float bladeWidth =
                    1.0 - smoothstep(0.025, 0.10,
                    abs(cell.x - bladeX));

                float bladeHeight =
                    1.0 - smoothstep(
                    0.35 + randomValue * 0.3,
                    0.65 + randomValue * 0.3,
                    cell.y);

                float blade = bladeWidth * bladeHeight;

                half3 grass =
                    lerp(_DarkGrass.rgb, _GrassColor.rgb, randomValue);

                grass = lerp(grass, _LightGrass.rgb, blade * 0.85);

                return half4(grass, 1);
            }

            ENDHLSL
        }
    }
}
