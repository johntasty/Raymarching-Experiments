using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class InvertColorsCompute : ScriptableRendererFeature
{
    class CustomRenderPass : ScriptableRenderPass
    {
        struct ShapeData
        {
            public Vector3 position;
        }
      
        private Material shader;
        private RenderTargetIdentifier sourceRT;      
        private int textureID;
    
        Vector2 dimensions;       
        public CustomRenderPass(RenderPassEvent Event, int Width, int Height, Material _Shader)
        {
            // Set the render pass event
            this.renderPassEvent = Event;


            textureID = Shader.PropertyToID("Result");           
            shader = _Shader;         
            dimensions = new Vector2(1f / Width, 1f / Height);
           
        }
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {

            RenderTextureDescriptor descriptor = renderingData.cameraData.cameraTargetDescriptor;
            descriptor.depthBufferBits = 0;
            descriptor.enableRandomWrite = true;
           
            cmd.GetTemporaryRT(textureID, descriptor, FilterMode.Bilinear);
            sourceRT = new RenderTargetIdentifier(textureID);
          
        }

       
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            
            var cmd = CommandBufferPool.Get("MyCustomRenderFeature");

            cmd.Blit(renderingData.cameraData.renderer.cameraColorTarget, sourceRT, shader);    
            // Blit the temporary render texture back to the camera's render texture.
            cmd.Blit(sourceRT, renderingData.cameraData.renderer.cameraColorTarget);
            context.ExecuteCommandBuffer(cmd);            
            cmd.Clear();            
            CommandBufferPool.Release(cmd);
            
        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(textureID);
           
           
        }
       
    }

    CustomRenderPass m_ScriptablePass; 
    [SerializeField]
    Material _Shader;
    [SerializeField]
    RenderPassEvent Event;
  
    [SerializeField]
    int width;
    [SerializeField]
    int height;
    /// <inheritdoc/>
    public override void Create()
    {
        m_ScriptablePass = new CustomRenderPass( Event, width, height, _Shader);
      
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_ScriptablePass);
    }
   
}


