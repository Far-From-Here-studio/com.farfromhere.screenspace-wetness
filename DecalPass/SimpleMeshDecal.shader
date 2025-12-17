Shader "Custom/HDRP/SimpleMeshDecal"
{
    Properties
    {
        _MainTex ("Decal Texture", 2D) = "white" {}
        [HDR]_Color ("Color", Color) = (1,1,1,1)
        [Toggle(USE_WORLD_SPACE)] _UseWorldSpace("Use World Space", Float) = 0
        _ClipThreshold("Surface Clip Threshold", Range(-0.1, 0.1)) = -0.01
        _LayerIndex("Rendering Layer Mask", float) = 0
    }

    SubShader
    {
        Tags { 
            "RenderType" = "Opaque"
            "Queue" = "Geometry"
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
                float _LayerIndex;
            CBUFFER_END


float DecalLayerMask(float RenderingLayerSample, float DecalLayerMask)
{
    // Sur la plupart des versions HDRP récentes, le mask est lisible dans .x.
    // Si votre node renvoie un float au lieu d’un float4, branchez-le sur .x côté graphe.
    uint sampled = (uint) round(RenderingLayerSample);
    uint wanted = (uint) round(DecalLayerMask);

    // 1.0 si au moins un bit correspond, sinon 0.0
    return ((sampled & wanted) != 0u) ? 1.0 : 0.0;
}

float1 Unity_HDRP_SampleBuffer_RenderingLayerMask_float(float2 uv, int layerID)
{
uint2 pixelCoords = uint2(uv * _ScreenSize.xy);
return _EnableRenderingLayers ? UnpackMeshRenderingLayerMask(LOAD_TEXTURE2D_X_LOD(_RenderingLayerMaskTexture, pixelCoords, 0)) : 0;
}

            



            Varyings vert(Attributes input)
            {
                Varyings output;
                
                // Transform positions
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.positionCS = TransformWorldToHClip(output.positionWS);
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
                color.a = DecalLayerMask(_LayerIndex, Unity_HDRP_SampleBuffer_RenderingLayerMask_float(screenUV,0)) * color.a;
                return color.rgba;
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

            
float DecalLayerMask(float RenderingLayerSample, float DecalLayerMask)
{
    // Sur la plupart des versions HDRP récentes, le mask est lisible dans .x.
    // Si votre node renvoie un float au lieu d’un float4, branchez-le sur .x côté graphe.
    uint sampled = (uint) round(RenderingLayerSample);
    uint wanted = (uint) round(DecalLayerMask);

    // 1.0 si au moins un bit correspond, sinon 0.0
    return ((sampled & wanted) != 0u) ? 1.0 : 0.0;
}

float1 Unity_HDRP_SampleBuffer_RenderingLayerMask_float(float2 uv, int layerID)
{
uint2 pixelCoords = uint2(uv * _ScreenSize.xy);
return _EnableRenderingLayers ? UnpackMeshRenderingLayerMask(LOAD_TEXTURE2D_X_LOD(_RenderingLayerMaskTexture, pixelCoords, 0)) : 0;
}



            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            //TEXTURE2D_X_FLOAT(_CameraDepthTexture);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _Color;
                float _ClipThreshold;
                float _LayerIndex;
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
                color.a = DecalLayerMask(_LayerIndex, Unity_HDRP_SampleBuffer_RenderingLayerMask_float(screenUV,0)) * color.a;
                return color.rgba;
            
            }
            ENDHLSL
        }

    }


}