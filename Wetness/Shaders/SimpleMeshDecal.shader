Shader "Custom/HDRP/SimpleMeshDecal"
{
    Properties
    {
        _MainTex ("Decal Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        [Toggle(USE_WORLD_SPACE)] _UseWorldSpace("Use World Space", Float) = 0
    }

    SubShader
    {
        Tags { 
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
            "RenderPipeline" = "HDRenderPipeline"
        }

        Pass
        {
            Name "Forward"
            Tags { "LightMode" = "ForwardOnly" }

            ZWrite Off
            ZTest Greater  // Only render on surfaces in front
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Front    // Render back faces

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature USE_WORLD_SPACE

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float4 projUV : TEXCOORD2;
                float2 uv : TEXCOORD3;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _Color;
            CBUFFER_END

            Varyings vert(Attributes input)
            {
                Varyings output;
                
                // Transform positions
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.positionCS = TransformWorldToHClip(output.positionWS);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                
                // Calculate projection UVs
                output.projUV = output.positionCS;
                output.uv = input.uv;
                
                return output;
            }

            float4 frag(Varyings input) : SV_Target
            {
                // Calculate UV coordinates based on position
                float2 projUV = input.projUV.xy / input.projUV.w;
                projUV = projUV * 0.5 + 0.5;
                
                // Sample texture using either world space or mesh UVs
                float4 color;
                #if USE_WORLD_SPACE
                    float2 worldUV = input.positionWS.xz * _MainTex_ST.xy + _MainTex_ST.zw;
                    color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, worldUV);
                #else
                    color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                #endif
                
                color *= _Color;
                
                // Fade out at edges of the projection
                float edge = 1 - abs(input.projUV.z);
                color.a *= smoothstep(0, 0.1, edge);
                
                return color;
            }
            ENDHLSL
        }
    }
}