using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
public class ParticleWaves : MonoBehaviour
{
    public ComputeShader ParticleWavesCompute;
    public Material HorizontalBlur;
    public Material BlurV;
    public Material Antialias;
    //public Material[] TestMats = new Material[4];
    public Material HeightMapShader;

    public int directionTest;

    public float[] speeds = new float[4];
    public float[] amps = new float[4];
    public int[] bounds = new int[4];
    public int[] particles = new int[4];
   
    public float timestep = 2;

    public RenderTexture[] outputTexturesArray;
    ComputeBuffer[] bufferArray;

    public RenderTexture WaveTexture;
    public RenderTexture Deviation;
    public RenderTexture Amplitude;
    public RenderTexture StackedTex;


    //ComputeBuffer bufferTest;
    int kernelHandle;
    int kernelHandleClear;
   
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

    public struct ParticleDataArrays
    {
        public Particle[] _ParticleDataS;
    }
    public ParticleDataArrays[] _ParticleDataArrays;
    
    public bool _Playing = true;

    RenderBuffer[] _mrt;
//TODO remap negative values to positive in direction
    void GenerateTextures()
    {
        outputTexturesArray = new RenderTexture[4];
        for (int i = 0; i < 4; i++)
        {
            outputTexturesArray[i] = new RenderTexture(_TextureSize, _TextureSize, 0, RenderTextureFormat.ARGB32);
            outputTexturesArray[i].wrapMode = TextureWrapMode.Repeat;
            outputTexturesArray[i].enableRandomWrite = true;
            outputTexturesArray[i].Create();
        }
    }
    void GenerateData()
    {
        _ParticleDataArrays = new ParticleDataArrays[4];
        float _time = Time.time;
        for (int x = 0; x < 4; x++)
        {
            Particle[] ParticleData = new Particle[particles[x]];
            Vector2 spawnRange = new Vector2(128, 128);
            for (int i = 0; i < particles[x]; i++)
            {
                Particle initial = new Particle();
                float radians = 2 * Mathf.PI / 64f * (i % 64f);
                Vector2 radial = new Vector2(Mathf.Cos(radians), Mathf.Sin(radians));
                Vector2 _spawn = spawnRange + radial * Random.Range(25f, 100f);

                initial.m_direction =  new Vector2(Random.Range(-1f, 1f), Random.Range(-1f, 1f));
                initial.m_origin = _spawn;
                initial.m_angle = radians;
                initial.subdivided = 0;
                initial.alive = 1;
                initial.m_timeAlive = _time;

                ParticleData[i] = initial;
            }
            _ParticleDataArrays[x]._ParticleDataS = ParticleData;
        }
    }
    void GenerateBuffers()
    {
        bufferArray = new ComputeBuffer[4];
        for (int i = 0; i < 4; i++)
        {
            bufferArray[i] = new ComputeBuffer(particles[i], sizeof(float) * 6 + sizeof(int) * 2);
            Particle[] data = _ParticleDataArrays[i]._ParticleDataS;
            bufferArray[i].SetData(data);
        }       
    }
    void ComputeDispatch()
    {
       
        kernelHandleClear = ParticleWavesCompute.FindKernel("CSClear");
        ParticleWavesCompute.SetFloat("_Time", alT);
        for (int i = 0; i < directionTest; i++)
        {
            int threads = particles[i] / 64;
            ParticleWavesCompute.SetTexture(kernelHandle, "Result", outputTexturesArray[i]);
            ParticleWavesCompute.SetTexture(kernelHandleClear, "Result", outputTexturesArray[i]);

            ParticleWavesCompute.SetBuffer(kernelHandle, "ParticlesBuffer", bufferArray[i]);


            ParticleWavesCompute.SetFloat("size", amps[i]);
            ParticleWavesCompute.SetFloat("speed", speeds[i]);
            ParticleWavesCompute.SetInt("maxDivisions", bounds[i]);

            ParticleWavesCompute.Dispatch(kernelHandleClear, _TextureSize / 8, _TextureSize / 8, 1);
            ParticleWavesCompute.Dispatch(kernelHandle, threads, 1, 1);
        }

    }
    void GenPostProcessTex()
    {       
        WaveTexture = new RenderTexture(_TextureSize, _TextureSize, 0, RenderTextureFormat.ARGB32);
        Deviation = new RenderTexture(_TextureSize, _TextureSize, 0, RenderTextureFormat.ARGBFloat);
        Amplitude = new RenderTexture(_TextureSize, _TextureSize, 0, RenderTextureFormat.ARGBFloat);
        StackedTex = new RenderTexture(_TextureSize, _TextureSize, 0, RenderTextureFormat.ARGB32);

        WaveTexture.wrapMode = TextureWrapMode.Repeat;
        Deviation.wrapMode = TextureWrapMode.Repeat;
        Amplitude.wrapMode = TextureWrapMode.Repeat;
        StackedTex.wrapMode = TextureWrapMode.Repeat;

        Deviation.Create();
        Amplitude.Create();
        WaveTexture.Create();
        StackedTex.Create();
    }
    void Start()
    {
        
        GenerateTextures();
        GenerateData();
        GenerateBuffers();
        ComputeDispatch();

        GenPostProcessTex();

        Antialias.SetTexture("_MainTex", outputTexturesArray[0]);
        Antialias.SetTexture("_SecondTex", outputTexturesArray[1]);
        Antialias.SetTexture("_ThirdTex", outputTexturesArray[2]);
        Antialias.SetTexture("_FourthTex", outputTexturesArray[3]);

        HorizontalBlur.SetTexture("_MainTex", StackedTex);
        HorizontalBlur.SetFloat("HW", (float)_TextureSize);
      
        _mrt = new RenderBuffer[2];
        _mrt[0] = Deviation.colorBuffer;
        _mrt[1] = Amplitude.colorBuffer;

        BlurV.SetTexture("_MainTex", Deviation);
        BlurV.SetTexture("_Secondary", Amplitude);
        BlurV.SetFloat("HW", (float)_TextureSize);

        //HeightMapShader.SetTexture("_NoiseTex", DetailTexture);
        HeightMapShader.SetTexture("_MainTex", WaveTexture);

    }
    private void OnDisable()
    {

        WaveTexture.Release();       
        Deviation.Release();
        Amplitude.Release();
        StackedTex.Release();

        //BlurVertical.Release();
        for (int i = 0; i < 4; i++)
        {
            outputTexturesArray[i].Release();
            bufferArray[i].Release();
            bufferArray[i].Dispose();
        }
        //bufferVelo.Release();
        //bufferVelo.Dispose();
        _mrt = null;
    }
    private void Update()
    {

        alT = Time.time * timestep;
       
        ComputeDispatch();

        Graphics.Blit(null, StackedTex, Antialias);
        Graphics.SetRenderTarget(_mrt, Deviation.depthBuffer);
        Graphics.Blit(null, HorizontalBlur);
        Graphics.Blit(null, WaveTexture, BlurV);
    }

   
   
}
