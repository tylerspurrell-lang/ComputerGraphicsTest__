Shader "Unlit/RoadReflection"
{
    Properties
    {
        _BaseColor ("Orb Color", Color) = (0.15, 0.5, 1, 1)
        _EnvironmentCube ("Environment Cubemap", Cube) = "" {}
        _ReflectionStrength ("Reflection Strength", Range(0, 2)) = 1
        _FresnelPower ("Fresnel Power", Range(0.5, 8)) = 3
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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURECUBE(_EnvironmentCube);
            SAMPLER(sampler_EnvironmentCube);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float _ReflectionStrength;
                float _FresnelPower;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                OUT.positionHCS =
                    TransformObjectToHClip(IN.positionOS.xyz);

                OUT.positionWS =
                    TransformObjectToWorld(IN.positionOS.xyz);

                OUT.normalWS =
                    TransformObjectToWorldNormal(IN.normalOS);

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float3 normal = normalize(IN.normalWS);

                // Calculate the direction toward the camera.
                float3 viewDir =
                    normalize(GetWorldSpaceViewDir(IN.positionWS));

                // Get the main light in the scene.
                Light mainLight = GetMainLight();

                // Diffuse lighting: brighter when facing the light.
                float NdotL =
                    saturate(dot(normal, mainLight.direction));

                half3 ambient = SampleSH(normal);

                half3 diffuse =
                    _BaseColor.rgb *
                    (ambient + mainLight.color * NdotL);

                // Reflection: sample the environment cubemap.
                float3 reflectionDir =
                    reflect(-viewDir, normal);

                half3 reflection = SAMPLE_TEXTURECUBE(
                    _EnvironmentCube,
                    sampler_EnvironmentCube,
                    reflectionDir
                ).rgb;

                // Fresnel: stronger reflections near the edges.
                float fresnel =
                    pow(
                        1.0 - saturate(dot(normal, viewDir)),
                        _FresnelPower
                    );

                half3 finalColor = diffuse +
                    reflection * _ReflectionStrength *
                    (0.2 + fresnel);

                return half4(finalColor, 1);
            }

            ENDHLSL
        }
    }
}
