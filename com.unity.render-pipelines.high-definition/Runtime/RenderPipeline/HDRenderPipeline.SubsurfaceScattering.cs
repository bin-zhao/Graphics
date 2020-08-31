using UnityEngine.Experimental.Rendering;
using UnityEngine.Experimental.Rendering.RenderGraphModule;

namespace UnityEngine.Rendering.HighDefinition
{
    public partial class HDRenderPipeline
    {
        // Albedo + SSS Profile and mask / Specular occlusion (when no SSS)
        // This will be used during GBuffer and/or forward passes.
        TextureHandle CreateSSSBuffer(RenderGraph renderGraph, bool msaa)
        {
            return renderGraph.CreateTexture(new TextureDesc(Vector2.one, true, true)
            {
                colorFormat = GraphicsFormat.R8G8B8A8_SRGB,
                enableRandomWrite = !msaa,
                bindTextureMS = msaa,
                enableMSAA = msaa,
                clearBuffer = NeedClearGBuffer(),
                clearColor = Color.clear,
                name = msaa ? "SSSBufferMSAA" : "SSSBuffer"
            });
        }

        class SubsurfaceScaterringPassData
        {
            public SubsurfaceScatteringParameters parameters;
            public TextureHandle colorBuffer;
            public TextureHandle diffuseBuffer;
            public TextureHandle depthStencilBuffer;
            public TextureHandle depthTexture;
            public TextureHandle cameraFilteringBuffer;
            public TextureHandle sssBuffer;
            public ComputeBufferHandle coarseStencilBuffer;
        }

        void RenderSubsurfaceScattering(RenderGraph renderGraph, HDCamera hdCamera, TextureHandle colorBuffer,
            in LightingBuffers lightingBuffers, ref PrepassOutput prepassOutput)
        {
            if (!hdCamera.frameSettings.IsEnabled(FrameSettingsField.SubsurfaceScattering))
                return;

            BuildCoarseStencilAndResolveIfNeeded(renderGraph, hdCamera, resolveOnly: false, ref prepassOutput);

            TextureHandle depthStencilBuffer = prepassOutput.depthBuffer;
            TextureHandle depthTexture = prepassOutput.depthPyramidTexture;

            using (var builder = renderGraph.AddRenderPass<SubsurfaceScaterringPassData>("Subsurface Scattering", out var passData, ProfilingSampler.Get(HDProfileId.SubsurfaceScattering)))
            {
                passData.parameters = PrepareSubsurfaceScatteringParameters(hdCamera);
                passData.colorBuffer = builder.WriteTexture(colorBuffer);
                passData.diffuseBuffer = builder.ReadTexture(lightingBuffers.diffuseLightingBuffer);
                passData.depthStencilBuffer = builder.ReadTexture(depthStencilBuffer);
                passData.depthTexture = builder.ReadTexture(depthTexture);
                passData.sssBuffer = builder.ReadTexture(lightingBuffers.sssBuffer);
                passData.coarseStencilBuffer = builder.ReadComputeBuffer(prepassOutput.coarseStencilBuffer);
                if (passData.parameters.needTemporaryBuffer)
                {
                    passData.cameraFilteringBuffer = builder.CreateTransientTexture(
                                            new TextureDesc(Vector2.one, true, true)
                                            { colorFormat = GraphicsFormat.B10G11R11_UFloatPack32, enableRandomWrite = true, clearBuffer = true, clearColor = Color.clear, name = "SSSCameraFiltering" });
                }

                builder.SetRenderFunc(
                (SubsurfaceScaterringPassData data, RenderGraphContext context) =>
                {
                    var resources = new SubsurfaceScatteringResources();
                    resources.colorBuffer = data.colorBuffer;
                    resources.diffuseBuffer = data.diffuseBuffer;
                    resources.depthStencilBuffer = data.depthStencilBuffer;
                    resources.depthTexture = data.depthTexture;
                    resources.cameraFilteringBuffer = data.cameraFilteringBuffer;
                    resources.sssBuffer = data.sssBuffer;
                    resources.coarseStencilBuffer = data.coarseStencilBuffer;

                    RenderSubsurfaceScattering(data.parameters, resources, context.cmd);
                });
            }
        }
    }
}
