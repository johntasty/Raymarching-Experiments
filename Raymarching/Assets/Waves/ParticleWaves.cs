using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
public class ParticleWaves : MonoBehaviour
{
    public ComputeShader ParticleWavesCompute;
    public Material WavesShader;
    public Material WavesShaderPass2;
    public Material BlurV;
    public Material BlurVetical;

    public Material HeightMapShader;

    public float speed;
    public float timeScale;
    public float gradient;
    public float size;
    public float _smooth;
    public int _partNum = 360;
    public int _Circles = 2;
    private RenderTexture outputTexture;

    //public RenderTexture BlurVertical;
    //public RenderTexture BlurSecondPass;
    //public RenderTexture BlurV45;
    public RenderTexture BlurHorizontal;
    public RenderTexture HeightMap;

    ComputeBuffer bufferVelo;
    //ComputeBuffer bufferTest;
    int kernelHandle;
    int kernelHandleClear;
    int kernelHandleBlurH;
    int kernelHandleBlurV;
    int kernelHandleBlurCor;

    public int _TextureSize = 1024;
    public int threadGroups = 0;
    public float al = 0;
    public float alT = 0;
    public float ArcDistance = 0;
    public float radiansStart = 0;
    [System.Serializable]
    public struct Particle
    {
        public float m_timeAlive;       
        public Vector2 m_origin;       
        public Vector2 m_direction;
        public float m_angle;
        public int alive;
        public int subdivided;
    };
    public Particle[] _ParticleData;
    public Particle[] _ParticleDataTest;
    
    public bool _Playing = true;
    
    // Start is called before the first frame update
    void Start()
    {

        outputTexture = new RenderTexture(_TextureSize, _TextureSize, 0, RenderTextureFormat.ARGB32);
        //BlurVertical = new RenderTexture(_TextureSize, _TextureSize, 0, RenderTextureFormat.ARGB32);
        //BlurV45 = new RenderTexture(_TextureSize, _TextureSize, 0, RenderTextureFormat.ARGB32);
        BlurHorizontal = new RenderTexture(_TextureSize, _TextureSize, 0, RenderTextureFormat.ARGB32);
        //BlurSecondPass = new RenderTexture(_TextureSize, _TextureSize, 0, RenderTextureFormat.ARGB32);
        HeightMap = new RenderTexture(_TextureSize, _TextureSize, 0, RenderTextureFormat.ARGB32);      
        
        outputTexture.enableRandomWrite = true;
        //BlurV45.enableRandomWrite = true;       
        outputTexture.wrapMode = TextureWrapMode.Clamp;
        //BlurSecondPass.wrapMode = TextureWrapMode.Clamp;
        HeightMap.wrapMode = TextureWrapMode.Clamp;
        BlurHorizontal.wrapMode = TextureWrapMode.Clamp;
        
       
        //BlurHorizontal.filterMode = FilterMode.Bilinear;
        HeightMap.filterMode = FilterMode.Bilinear;
        outputTexture.Create();

        //BlurVertical.Create();
        //BlurV45.Create();
        BlurHorizontal.Create();
        HeightMap.Create();
        //BlurSecondPass.Create();


        kernelHandleClear = ParticleWavesCompute.FindKernel("CSClear");
       
        ParticleWavesCompute.SetTexture(kernelHandle, "Result", outputTexture);
       
        ParticleWavesCompute.SetTexture(kernelHandleClear, "Result", outputTexture);
      
        _ParticleData = new Particle[_partNum];
        _ParticleDataTest = new Particle[_partNum];
       
       
        float radius = 5;
        float YY = 0;
        Vector2 start = new Vector2(0, 0);
        float _time = Time.time;
        // Populate the initial data with values
        radiansStart = 2 * Mathf.PI / 8f;
        for (int i = 0; i < _partNum; i++)
        {
            Particle initial = new Particle();
            
            initial.m_origin = start;
            initial.subdivided = 0;
            initial.m_direction = new Vector2(0, 0);
            initial.alive = 0;
            _ParticleData[i] = initial;
            //if (i % 512 == 0 && i != 0) YY++;
            if (i % 64 == 0)
            {
                float radians = 2 * Mathf.PI / 8f * YY;
                
                Vector2 radial = new Vector2(Mathf.Cos(radians), Mathf.Sin(radians));
                Vector2 _spawn = new Vector2(256, 256) + radial * radius;
                initial.m_origin = _spawn;

                Vector2 direction = _spawn - new Vector2(256, 256);

                initial.m_direction = direction.normalized;
                initial.m_angle = radiansStart;
                initial.alive = 1;
                initial.subdivided = 0;
                initial.m_timeAlive = _time;
                _ParticleData[i] = initial;
                YY++;
            }
        }
       //Arc distance at 0
        float distanO = radius * radiansStart;
        al = distanO;


        bufferVelo = new ComputeBuffer(_partNum, sizeof(float) * 6 + sizeof(int)* 2 );
        //bufferTest = new ComputeBuffer(_partNum * _Circles, sizeof(float) * 4 + sizeof(int));
       
        bufferVelo.SetData(_ParticleData);
        //bufferTest.SetData(_ParticleDatas);
        
        threadGroups = _partNum / 64;//Mathf.Max(1,(int)Mathf.Sqrt(_partNum * _Circles) / 8);
        // Pass the buffer to the compute shader
        ParticleWavesCompute.SetBuffer(kernelHandle, "ParticlesBuffer", bufferVelo);

        ParticleWavesCompute.SetFloat("distanceZero", distanO);
        ParticleWavesCompute.SetFloat("size", size);
        ParticleWavesCompute.Dispatch(kernelHandle, threadGroups, 1, 1);

        WavesShader.SetTexture("_MainTex", HeightMap);

        HeightMapShader.SetTexture("_NoiseTex", BlurHorizontal);

        StartCoroutine(Tick());
       

    }
    private void OnDisable()
    {
        outputTexture.Release();
        BlurHorizontal.Release();
        //BlurV45.Release();
        //BlurVertical.Release();
        HeightMap.Release();

        bufferVelo.Dispose();

        RenderPipelineManager.endCameraRendering -= RenderPipelineManager_endCameraRendering;

    }
    private void OnEnable()
    {
        RenderPipelineManager.endCameraRendering += RenderPipelineManager_endCameraRendering;
    }
    private void RenderPipelineManager_endCameraRendering(ScriptableRenderContext context, Camera camera)
    {
        OnPostRender();
    }
   
    private IEnumerator Tick()
    {
        while (_Playing)
        {
            
            alT = Time.time;
            ArcDistance = al + radiansStart * speed * alT;

            ParticleWavesCompute.SetFloat("_Time", alT);
            ParticleWavesCompute.SetFloat("timeScale", timeScale);
            ParticleWavesCompute.SetFloat("gradient", gradient);
            ParticleWavesCompute.SetFloat("size", size);
            ParticleWavesCompute.SetFloat("speed", speed);
            ParticleWavesCompute.SetFloat("smooth", _smooth * Mathf.Deg2Rad);
            ParticleWavesCompute.Dispatch(kernelHandleClear, _TextureSize / 8, _TextureSize / 8, 1);
            ParticleWavesCompute.Dispatch(kernelHandle, threadGroups, 1, 1);

            bufferVelo.GetData(_ParticleDataTest);
            
            //WavesShader.SetTexture("_MainTex", BlurHorizontal);

            //Graphics.Blit(BlurHorizontal, BlurVertical, WavesShaderPass2);
            //WavesShaderPass2.SetTexture("_MainTex", BlurVertical);

            //Graphics.Blit(BlurHorizontal, HeightMap);
            //HeightMapShader.SetTexture("_NoiseTex", BlurHorizontal);
            Graphics.Blit(outputTexture, BlurHorizontal, WavesShader);
            yield return null;
        }       
    }
    private void OnPostRender()
    {
       

    }
   
}
