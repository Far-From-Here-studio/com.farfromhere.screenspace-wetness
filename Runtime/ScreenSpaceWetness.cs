using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.HighDefinition;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;


namespace FFH.HDRP.Rendering
{
#if UNITY_EDITOR
    using UnityEditor.Rendering.HighDefinition;

    [CustomPassDrawer(typeof(ScreenSpaceWetness))]
    class ScreenSpaceWetnessEditor : CustomPassDrawer
    {
        protected override PassUIFlag commonPassUIFlags => PassUIFlag.Name;
    }
#endif

    public class ScreenSpaceWetness : CustomPass
    {
        public Material wetnessMaterial;
        public CustomRenderTexture GlidingDroplets;
        RTHandle tmpNormalBuffer;
        MaterialPropertyBlock props;

        protected override void Setup(ScriptableRenderContext renderContext, CommandBuffer cmd)
        {
            tmpNormalBuffer = RTHandles.Alloc(Vector2.one, 
                TextureXR.slices, dimension: TextureXR.dimension,
                colorFormat: GraphicsFormat.R16G16B16A16_SFloat,
                useDynamicScale: true,
                name: "TMP Normal Buffer");
        }

        public override IEnumerable<Material> RegisterMaterialForInspector()
        {
            if (wetnessMaterial != null)
                yield return wetnessMaterial;
        }

        protected override void Execute(CustomPassContext ctx)
        {
            if (ctx.hdCamera.camera.cameraType == CameraType.SceneView)
            {
                ctx.cmd.SetRenderTarget(ctx.cameraColorBuffer, ctx.cameraDepthBuffer);
                ctx.cmd.SetViewport(ctx.hdCamera.camera.pixelRect);
            }

            if (injectionPoint != CustomPassInjectionPoint.AfterOpaqueDepthAndNormal)
            {
                Debug.LogError("Custom Pass ScreenSpaceWetness needs to be used at the injection point AfterOpaqueDepthAndNormal.");
                return;
            }

            if (wetnessMaterial == null)
                return;

            props = new MaterialPropertyBlock();
            CoreUtils.SetRenderTarget(ctx.cmd, tmpNormalBuffer, ctx.cameraDepthBuffer);
            CoreUtils.DrawFullScreen(ctx.cmd, wetnessMaterial, shaderPassId: 0, properties: props);
            CustomPassUtils.Copy(ctx, tmpNormalBuffer, ctx.cameraNormalBuffer);
        }

        protected override void Cleanup()
        {
            tmpNormalBuffer.Release();
        }
    }
}