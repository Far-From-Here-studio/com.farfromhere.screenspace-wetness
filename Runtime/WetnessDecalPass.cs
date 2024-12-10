using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;
using UnityEngine.Rendering.RendererUtils;


namespace FFH.HDRP.Rendering
{
#if UNITY_EDITOR

    using UnityEditor.Rendering.HighDefinition;

    [CustomPassDrawer(typeof(WetnessDecalPass))]
    class WetnessDecalPassEditor : CustomPassDrawer
    {
        protected override PassUIFlag commonPassUIFlags => PassUIFlag.Name;
    }
#endif
    public class WetnessDecalPass : CustomPass
    {
        public RenderTexture renderTexture;
        RTHandle tmpDecalBuffer;
        private MaterialPropertyBlock props;
        private ShaderTagId WetnessDecalShaderTagId;
        private ShaderTagId[] WetnessDecalShaderTagPasses;
        public RenderQueueType renderQueueType = RenderQueueType.AllOpaque;
        public LayerMask layerMask = 1; // Layer mask Default enabled
        public bool overrideDepthState = false;
        public bool depthWrite = false;
        public CompareFunction depthCompareFunction = CompareFunction.LessEqual;



        protected override void Setup(ScriptableRenderContext renderContext, CommandBuffer cmd)
        {
            tmpDecalBuffer = RTHandles.Alloc(renderTexture);
            /*
            tmpDecalBuffer = RTHandles.Alloc(Vector2.one,
                TextureXR.slices,
                dimension: TextureXR.dimension,
                colorFormat: GraphicsFormat.R16G16B16A16_SFloat,
                useDynamicScale: true,
                name: "TMP Normal Buffer");
            */

            WetnessDecalShaderTagId = new ShaderTagId("WetnessDecals");
            WetnessDecalShaderTagPasses = new ShaderTagId[] { WetnessDecalShaderTagId };

        }

        protected override void Execute(CustomPassContext ctx)
        {
            if (ctx.hdCamera.camera.cameraType == CameraType.SceneView)
            {
                ctx.cmd.SetRenderTarget(ctx.cameraColorBuffer, ctx.cameraDepthBuffer);
                ctx.cmd.SetViewport(ctx.hdCamera.camera.pixelRect);
            }
            if (!tmpDecalBuffer.rt) return;


            //ctx.cmd.CopyTexture(ctx.cameraDepthBuffer, tmpDecalBuffer);

            //CoreUtils.SetRenderTarget(ctx.cmd, tmpDecalBuffer);
            ctx.cmd.ClearRenderTarget(false, true, Color.black);

            PerObjectData renderConfig = HDUtils.GetRendererConfiguration(false, false);

            var mask = overrideDepthState ? RenderStateMask.Depth : 0;
            mask |= overrideDepthState && !depthWrite ? RenderStateMask.Stencil : 0;

            var stateBlock = new RenderStateBlock(mask)
            {
                depthState = new DepthState(depthWrite, depthCompareFunction),
            };

            var result = new RendererListDesc(WetnessDecalShaderTagPasses, ctx.cullingResults, ctx.hdCamera.camera)
            {
                rendererConfiguration = renderConfig,
                renderQueueRange = GetRenderQueueRange(renderQueueType),
                excludeObjectMotionVectors = true,
                stateBlock = stateBlock,
                layerMask = layerMask,
            };
            var rendererList = ctx.renderContext.CreateRendererList(result);

            CoreUtils.DrawRendererList(ctx.renderContext, ctx.cmd, rendererList);

        }
        protected override void Cleanup()
        {
            tmpDecalBuffer.Release();
        }
    }
}