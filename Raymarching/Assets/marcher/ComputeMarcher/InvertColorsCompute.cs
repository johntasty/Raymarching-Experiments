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
        ComputeShader _Compute;
        private int kernelIndex;
        private int kernelIndexs;

        private RenderTargetIdentifier sourceRT;
        private RenderTargetIdentifier DestinationRt;
        private int textureID;
        private int textureIDdest;

        private int NumShapes = 1;
        private float Radius = 1;
        float _Smooth;
        int _MaxSteps;
        float _MaxDist;
        private ComputeBuffer shapeBuffer;
        private int SizeBuffer;
        float _Radius;
        public CustomRenderPass(ComputeShader compute, RenderPassEvent Event, int bufferSize, float _Smooths, float Radius,int steps, float distance)
        {
            // Set the render pass event
            this.renderPassEvent = Event;
            _Compute = compute;
            kernelIndex = _Compute.FindKernel("InvertColors");
            kernelIndexs = _Compute.FindKernel("DispatchTest");
            textureID = Shader.PropertyToID("Result");
            textureIDdest = Shader.PropertyToID("Destination");

            SizeBuffer = bufferSize;
            //shapeBuffer = new ComputeBuffer(SizeBuffer, sizeof(float) * 3);
            _Smooth = _Smooths;
            _Radius = Radius;
            _MaxSteps = steps;
            _MaxDist = distance;
        }
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {

            RenderTextureDescriptor descriptor = renderingData.cameraData.cameraTargetDescriptor;
            descriptor.depthBufferBits = 0;
            descriptor.enableRandomWrite = true;
           
            cmd.GetTemporaryRT(textureID, descriptor, FilterMode.Bilinear);
            sourceRT = new RenderTargetIdentifier(textureID);
            cmd.GetTemporaryRT(textureIDdest, descriptor, FilterMode.Bilinear);
            DestinationRt = new RenderTargetIdentifier(textureIDdest);
        }

       
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            //if (renderingData.cameraData.isSceneViewCamera)
            //    return;
            var cmd = CommandBufferPool.Get("MyCustomRenderFeature");

            cmd.Blit(renderingData.cameraData.renderer.cameraColorTarget, sourceRT);                        
            cmd.SetComputeTextureParam(_Compute, kernelIndex, textureID, sourceRT);
            cmd.SetComputeTextureParam(_Compute, kernelIndex, textureIDdest, DestinationRt);

            cmd.SetComputeMatrixParam(_Compute, "_CameraToWorld", renderingData.cameraData.camera.cameraToWorldMatrix);
            cmd.SetComputeMatrixParam(_Compute, "_CameraInverseProjection", renderingData.cameraData.camera.projectionMatrix.inverse);
                       
            cmd.SetComputeIntParam(_Compute, "numShapes", SizeBuffer);

            cmd.SetComputeFloatParam(_Compute, "_radius", _Radius);
            cmd.SetComputeFloatParam(_Compute, "_Time", Time.deltaTime);
            cmd.SetComputeFloatParam(_Compute, "_Smooth", _Smooth);
            cmd.SetComputeIntParam(_Compute, "maxSteps", _MaxSteps);
            cmd.SetComputeFloatParam(_Compute, "maxDst", _MaxDist);

            cmd.DispatchCompute(_Compute, kernelIndex, Mathf.CeilToInt(renderingData.cameraData.cameraTargetDescriptor.width / 8f), Mathf.CeilToInt(renderingData.cameraData.cameraTargetDescriptor.height / 8f), 1);
            cmd.DispatchCompute(_Compute, kernelIndexs, Mathf.CeilToInt(renderingData.cameraData.cameraTargetDescriptor.width / 8f), Mathf.CeilToInt(renderingData.cameraData.cameraTargetDescriptor.height / 8f), 1);
            
            // Blit the temporary render texture back to the camera's render texture.
            cmd.Blit(DestinationRt, renderingData.cameraData.renderer.cameraColorTarget);
           

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
    ComputeShader _ComputeShader;
    [SerializeField]
    RenderPassEvent Event;
    [SerializeField]
    int _BufferNum;
    [SerializeField]
    float _Smooth;
    [SerializeField]
    float _Radius;
    [SerializeField]
    int _MaxSteps;
    [SerializeField]
    float _MaxDist;
    /// <inheritdoc/>
    public override void Create()
    {
        m_ScriptablePass = new CustomRenderPass(_ComputeShader, Event, _BufferNum, _Smooth, _Radius, _MaxSteps, _MaxDist);
      
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_ScriptablePass);
    }
   
}


