using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;
using UnityEngine;

namespace FFH.HDRP.Rendering
{
#if UNITY_EDITOR

    using UnityEditor.Rendering.HighDefinition;

    [CustomPassDrawer(typeof(VFXElementsRenderer))]
    class VFXElementsRendererEditor : CustomPassDrawer
    {
        protected override PassUIFlag commonPassUIFlags => PassUIFlag.Name;
    }

#endif
    class VFXElementsRenderer : CustomPass
    {
        public LayerMask DefaultLayerMask = 1;
        public RenderTexture VFXBufferRT;
        public Camera VFXOrthoCamera;
        RTHandle VFXBuffer;
        private MaterialPropertyBlock props;

        protected override void Setup(ScriptableRenderContext renderContext, CommandBuffer cmd)
        {
            if (VFXBufferRT) VFXBuffer = RTHandles.Alloc(VFXBufferRT);
            props = new MaterialPropertyBlock();

            cmd.SetRenderTarget(VFXBuffer);
        }
        protected override void Execute(CustomPassContext ctx)
        {
            if (VFXOrthoCamera && VFXBufferRT)
            {
                VFXOrthoCamera.targetTexture = VFXBuffer;
                ctx.cmd.SetRenderTarget(VFXBuffer);
                ctx.cmd.ClearRenderTarget(true, true, Color.black);

                if (VFXOrthoCamera.TryGetCullingParameters(out var cullingParams))
                {
                    cullingParams.cullingOptions = CullingOptions.None;
                    ctx.cullingResults = ctx.renderContext.Cull(ref cullingParams);
                }
                CustomPassUtils.RenderFromCamera(ctx, VFXOrthoCamera, DefaultLayerMask);
            }
        }
        protected override void Cleanup()
        {
            //RTHandles.Release(VFXBuffer);
        }
    }
}