Shader "Unlit/SmokeEffect"
{

    Properties
    {
        _smokeColor ("smoke Color", Color) = (0.05, 0.8, 1, 1)
        _GlowColor ("Glow Color", Color) = (0.5, 0.1, 1, 1)

        _VertexAmplitude ("Pulse Amount", Range(0, 0.3)) = 0.08
        _PulseSpeed ("Pulse Speed", Range(0, 5)) = 2
        _WaveFrequency ("Wave Frequency", Range(0, 10)) = 3

        _StripeSpeed ("Stripe Speed", Range(0, 5)) = 1.5
        _StripeFrequency ("Stripe Frequency", Range(1, 30)) = 12
        _GlowIntensity ("Glow Intensity", Range(0, 5)) = 2
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
                half4 _smokeColor;
                half4 _GlowColor;
                float _VertexAmplitude;
                float _PulseSpeed;
                float _WaveFrequency;
                float _StripeSpeed;
                float _StripeFrequency;
                float _GlowIntensity;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 positionOS : TEXCOORD1;
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                // Animate the smoke vertices over time.
                float wave = sin(
                    _Time.y * _PulseSpeed
                    + IN.positionOS.y * _WaveFrequency
                );

                // Push vertices along their normals.
                IN.positionOS.xyz +=
                    IN.normalOS * wave * _VertexAmplitude;

                // Transform the modified position to clip space.
                OUT.positionHCS =
                    TransformObjectToHClip(IN.positionOS.xyz);

                OUT.uv = IN.uv;
                OUT.positionOS = IN.positionOS.xyz;

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                // Animate a stripe pattern using UV coordinates.
                float stripe = sin(
                    (IN.uv.y * _StripeFrequency
                    - _Time.y * _StripeSpeed)
                    * 6.28318
                );

                // Convert the stripe pattern into a 0-to-1 mask.
                float pattern = smoothstep(-0.2, 0.8, stripe);

                // Blend the main smoke color with the magical color.
                half3 smoke = lerp(
                    _smokeColor.rgb,
                    _GlowColor.rgb,
                    pattern
                );

                // Make the smoke brighten and dim over time.
                float pulse = 0.75 + 0.25 *
                    sin(_Time.y * _PulseSpeed);

                half3 finalColor =
                    smoke * _GlowIntensity * pulse;

                return half4(finalColor, 1);
            }

            ENDHLSL
        }
    }
}



