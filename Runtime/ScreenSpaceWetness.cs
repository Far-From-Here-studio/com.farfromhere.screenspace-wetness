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
        RTHandle tmpBuffer;
        MaterialPropertyBlock props;
        public RenderTexture RT;
        static class ShaderID
        {
            public static readonly int _WetnessBuffer = Shader.PropertyToID("_WetnessBuffer");
        }

        protected override void Setup(ScriptableRenderContext renderContext, CommandBuffer cmd)
        {

            tmpBuffer = RTHandles.Alloc(Vector2.one,
                TextureXR.slices, dimension: TextureXR.dimension,
                colorFormat: GraphicsFormat.R8G8B8A8_UNorm,
                depthBufferBits: DepthBits.None,
                useDynamicScale: true,
                name: "_WetnessBuffer");

        }

        public override IEnumerable<Material> RegisterMaterialForInspector()
        {
            if (wetnessMaterial != null)
                yield return wetnessMaterial;
        }

        protected override void Execute(CustomPassContext ctx)
        {
            /*
            if (injectionPoint != CustomPassInjectionPoint.AfterOpaqueDepthAndNormal)
            {
                Debug.LogError("Custom Pass ScreenSpaceWetness needs to be used at the injection point AfterOpaqueDepthAndNormal.");
                return;
            }
           */

            if (wetnessMaterial == null)
                return;

            props = new MaterialPropertyBlock();
            CoreUtils.SetRenderTarget(ctx.cmd, tmpBuffer);
            CoreUtils.DrawFullScreen(ctx.cmd, wetnessMaterial, shaderPassId: 0, properties: props);
            ctx.cmd.SetGlobalTexture(ShaderID._WetnessBuffer, tmpBuffer.rt);
            RT = tmpBuffer.rt;
        }

        protected override void Cleanup()
        {
            tmpBuffer.Release();
        }
    }
}