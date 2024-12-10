Shader "Renderers/WetnessDecals"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _ColorMap("ColorMap", 2D) = "white" {}

        // Transparency
        _AlphaCutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        [HideInInspector]_BlendMode("_BlendMode", Range(0.0, 1.0)) = 0.5
    }

    HLSLINCLUDE

    #pragma target 4.5
    #pragma only_renderers d3d11 playstation xboxone xboxseries vulkan metal switch

    // #pragma enable_d3d11_debug_symbols

    //enable GPU instancing support
    #pragma multi_compile_instancing
    #pragma multi_compile _ DOTS_INSTANCING_ON

    ENDHLSL

    SubShader
    {
        Tags{ "RenderPipeline" = "HDRenderPipeline" }
        Pass
        {
            Name "WetnessDecals"
            Tags { "LightMode" = "WetnessDecals" }

            Blend Off
            ZWrite Off
            ZTest LEqual

            Cull Back

            HLSLPROGRAM

            // Toggle the alpha test
            #define _ALPHATEST_ON

            // Toggle transparency
            #define _SURFACE_TYPE_TRANSPARENT

            // Toggle fog on transparent
            //#define _ENABLE_FOG_ON_TRANSPARENT
            
            // List all the attributes needed in your shader (will be passed to the vertex shader)
            // you can see the complete list of these attributes in VaryingMesh.hlsl
            #define ATTRIBUTES_NEED_TEXCOORD0
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT

            // List all the varyings needed in your fragment shader
            #define VARYINGS_NEED_TEXCOORD0
            #define VARYINGS_NEED_TANGENT_TO_WORLD

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            
            TEXTURE2D(_ColorMap);

            // Declare properties in the UnityPerMaterial cbuffer to make the shader compatible with SRP Batcher.
CBUFFER_START(UnityPerMaterial)
            float4 _ColorMap_ST;
            float4 _Color;

            float _AlphaCutoff;
            float _BlendMode;
CBUFFER_END

            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/RenderPass/CustomPass/CustomPassRenderersV2.hlsl"

            StructuredBuffer<int2> _DepthPyramidMipLevelOffsets;
            float Unity_HDRP_SampleSceneDepth_float(float2 uv, float lod)
            {
                int2 coord = int2(uv * _ScreenSize.xy);
                int2 mipCoord  = coord.xy >> int(lod);
                int2 mipOffset = _DepthPyramidMipLevelOffsets[int(lod)];
                return LOAD_TEXTURE2D_X(_CameraDepthTexture, mipOffset + mipCoord).r;
            }
            void Unity_Multiply_float4x4_float4(float4x4 A, float3 B, out float3 Out)
            {
            Out = mul(A, B);
            }

            // If you need to modify the vertex datas, you can uncomment this code
            // Note: all the transformations here are done in object space
            // #define HAVE_MESH_MODIFICATION
            // AttributesMesh ApplyMeshModification(AttributesMesh input, float3 timeParameters)
            // {
            //     input.positionOS += input.normalOS * 0.0001; // inflate a bit the mesh to avoid z-fight
            //     return input;
            // }

            // Put the code to render the objects in your custom pass in this function
            void GetSurfaceAndBuiltinData(FragInputs fragInputs, float3 viewDirection, inout PositionInputs posInput, out SurfaceData surfaceData, out BuiltinData builtinData)
            {
                float2 colorMapUv = TRANSFORM_TEX(fragInputs.texCoord0.xy, _ColorMap);
                float4 result = SAMPLE_TEXTURE2D(_ColorMap, s_trilinear_clamp_sampler, colorMapUv) * _Color;
                float Depth = Unity_HDRP_SampleSceneDepth_float(posInput.positionNDC,0);

                float3 normalizedspace = float3(posInput.positionNDC.x -0.5,(-1 * (posInput.positionNDC.y-0.5)), Depth);
                float4 inverseTransformMatrix = mul(UNITY_MATRIX_I_V, normalizedspace);

                float3 homogenouscoords = (inverseTransformMatrix.rgb)/ inverseTransformMatrix.a;
                float3 ClipSpace = TransformWorldToObject(homogenouscoords);
                
                float3 upperbound = step(-0.5,ClipSpace);
                float3 downbound = 1- step(0.5, ClipSpace);
                bool bound = all(upperbound * downbound);
                float alphabound = bound? 1 : 0;

                float opacity = bound;
                float3 color = result.rgb;

#ifdef _ALPHATEST_ON
                DoAlphaTest(opacity, _AlphaCutoff);
#endif
                
                // Write back the data to the output structures
                ZERO_BUILTIN_INITIALIZE(builtinData); // No call to InitBuiltinData as we don't have any lighting
                ZERO_INITIALIZE(SurfaceData, surfaceData);
                builtinData.opacity = opacity;
                builtinData.emissiveColor = float3(0, 0, 0);
                surfaceData.color = color;
            }

            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPassForwardUnlit.hlsl"

            #pragma vertex Vert
            #pragma fragment Frag

            ENDHLSL
        }
    }
}
