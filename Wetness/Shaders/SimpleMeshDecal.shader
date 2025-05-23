Shader "Custom/HDRP/SimpleMeshDecal"
{
    Properties
    {
        _MainTex ("Decal Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        [Toggle(USE_WORLD_SPACE)] _UseWorldSpace("Use World Space", Float) = 0
        _ClipThreshold("Surface Clip Threshold", Range(-0.1, 0.1)) = -0.01
        _ProjectionScale("Projection Scale", Vector) = (1,1,1)
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
            Name "WetnessDecal"
            Tags { "LightMode" = "WetnessDecal" }

            Cull Front
            ZWrite Off
            ZTest Always
            Blend SrcAlpha OneMinusSrcAlpha // Render back faces

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
                float depth : TEXCOORD1;
                float3 projUV : TEXCOORD2;
                float2 uv : TEXCOORD3;
                float3 ray : TEXCOORD4;

            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            //TEXTURE2D_X_FLOAT(_CameraDepthTexture);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _Color;
                float _ClipThreshold;
                float3 _ProjectionScale;
            CBUFFER_END

            Varyings vert(Attributes input)
            {
                Varyings output;
                
                // Transform positions
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.positionCS = TransformWorldToHClip(output.positionWS);
                //output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.ray = GetAbsolutePositionWS(output.positionWS) - _WorldSpaceCameraPos;
                // Calculate projection UVs
                output.projUV = GetAbsolutePositionWS(output.positionWS);
                output.depth = output.positionCS.w;
                output.uv = input.uv;
                
                return output;
            }


            float4 frag(Varyings input) : SV_Target
            {
                // Get the screen UV coordinates
                float2 screenUV = input.positionCS.xy / _ScreenSize.xy;;
                float2 posCS = (input.positionCS.x, - input.positionCS.y);
                float2 positionNDC = (posCS.xy / input.positionCS.w); // from -1 to 1
                
                float3 worldRay = normalize(input.ray);
                worldRay /= dot(worldRay, -UNITY_MATRIX_V[2].xyz);

                
                float rawSceneDepth = LOAD_TEXTURE2D_X(_CameraDepthTexture, input.positionCS.xy).r;
                float linearSceneDepth = ComputeViewSpacePosition(positionNDC, rawSceneDepth, UNITY_MATRIX_I_P).z;
                // Sample scene depth
                //float linearFragDepth = LinearEyeDepth(input.positionWS, UNITY_MATRIX_I_P);
                //float fragmentDepth = input.positionCS.w;
                //float depth = Linear01Depth(rawSceneDepth,_ZBufferParams.xyzw );

                float3 worldPos =  worldRay * linearSceneDepth; // * linearSceneDepth;
                float3 localPos = TransformWorldToObject(worldPos).xyz;

                clip(0.5 + _ClipThreshold - abs(localPos));
                
                   // Sample texture using either world space or mesh UVs
                float4 color;
                #if USE_WORLD_SPACE
                    float2 worldUV = input.positionWS.xz * _MainTex_ST.xy + _MainTex_ST.zw;
                    color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, worldUV);
                #else
                    color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, localPos.xz + 0.5);
                #endif
                
                color *= _Color; 

                return color.rgba;

                // Calculate depth difference
                //float depthDiff = abs( input.depth - linearSceneDepth );
                //clip(depthDiff + _ClipThreshold);
                               
                //if (input.depth + _ClipThreshold < linearSceneDepth )
                // discard;
               
                // Clip fragments that are too far from surfaces

                
               /*
                // Calculate UV coordinates based on position
                float2 projUV = input.projUV.xy / input.projUV.w;
                projUV = projUV * 0.5 + 0.5;
                
          
                
                // Fade based on depth difference for smoother edges
                float fade = 1 - (depthDiff / _ClipThreshold);
                color.a *= saturate(fade);                
                //return color;
                */
                
                /*
                float4x4 worldToObject = RevertCameraTranslationFromInverseMatrix(UNITY_MATRIX_I_M);
                float3 localPos = mul((float3x3)worldToObject, input.projUV.rgb);
                float3 uvw = localPos / _ProjectionScale;

           
                if (any(abs(uvw) > 0.5))
                    discard;
                         */
                         

            
            }
            ENDHLSL
        }
        Pass
        {
            Name "SceneViewForward"
            Tags { "LightMode" = "SceneViewForward" }

            Cull Front
            ZWrite Off
            ZTest Always
            Blend SrcAlpha OneMinusSrcAlpha // Render back faces

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
                float depth : TEXCOORD1;
                float3 projUV : TEXCOORD2;
                float2 uv : TEXCOORD3;
                float3 ray : TEXCOORD4;

            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            //TEXTURE2D_X_FLOAT(_CameraDepthTexture);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _Color;
                float _ClipThreshold;
                float3 _ProjectionScale;
            CBUFFER_END

            Varyings vert(Attributes input)
            {
                Varyings output;
                
                // Transform positions
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.positionCS = TransformWorldToHClip(output.positionWS);
                //output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.ray = GetAbsolutePositionWS(output.positionWS) - _WorldSpaceCameraPos;
                // Calculate projection UVs
                output.projUV = GetAbsolutePositionWS(output.positionWS);
                output.depth = output.positionCS.w;
                output.uv = input.uv;
                
                return output;
            }


            float4 frag(Varyings input) : SV_Target
            {
                // Get the screen UV coordinates
                float2 screenUV = input.positionCS.xy / _ScreenSize.xy;;
                float2 posCS = (input.positionCS.x, - input.positionCS.y);
                float2 positionNDC = (posCS.xy / input.positionCS.w); // from -1 to 1
                
                float3 worldRay = normalize(input.ray);
                worldRay /= dot(worldRay, -UNITY_MATRIX_V[2].xyz);

                
                float rawSceneDepth = LOAD_TEXTURE2D_X(_CameraDepthTexture, input.positionCS.xy).r;
                float linearSceneDepth = ComputeViewSpacePosition(positionNDC, rawSceneDepth, UNITY_MATRIX_I_P).z;
                // Sample scene depth
                //float linearFragDepth = LinearEyeDepth(input.positionWS, UNITY_MATRIX_I_P);
                //float fragmentDepth = input.positionCS.w;
                //float depth = Linear01Depth(rawSceneDepth,_ZBufferParams.xyzw );

                float3 worldPos =  worldRay * linearSceneDepth; // * linearSceneDepth;
                float3 localPos = TransformWorldToObject(worldPos).xyz;

                clip(0.5 + _ClipThreshold - abs(localPos));
                
                   // Sample texture using either world space or mesh UVs
                float4 color;
                #if USE_WORLD_SPACE
                    float2 worldUV = input.positionWS.xz * _MainTex_ST.xy + _MainTex_ST.zw;
                    color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, worldUV);
                #else
                    color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, localPos.xz + 0.5);
                #endif
                
                color *= _Color; 

                return color.rgba;

                // Calculate depth difference
                //float depthDiff = abs( input.depth - linearSceneDepth );
                //clip(depthDiff + _ClipThreshold);
                               
                //if (input.depth + _ClipThreshold < linearSceneDepth )
                // discard;
               
                // Clip fragments that are too far from surfaces

                
               /*
                // Calculate UV coordinates based on position
                float2 projUV = input.projUV.xy / input.projUV.w;
                projUV = projUV * 0.5 + 0.5;
                
          
                
                // Fade based on depth difference for smoother edges
                float fade = 1 - (depthDiff / _ClipThreshold);
                color.a *= saturate(fade);                
                //return color;
                */
                
                /*
                float4x4 worldToObject = RevertCameraTranslationFromInverseMatrix(UNITY_MATRIX_I_M);
                float3 localPos = mul((float3x3)worldToObject, input.projUV.rgb);
                float3 uvw = localPos / _ProjectionScale;

           
                if (any(abs(uvw) > 0.5))
                    discard;
                         */
                         

            
            }
            ENDHLSL
        }

    }


}