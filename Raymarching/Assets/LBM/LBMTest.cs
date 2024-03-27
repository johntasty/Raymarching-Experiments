using System;
using System.Collections;
using UnityEngine;

public class LBMTest : MonoBehaviour
{
    [SerializeField]
    Terrain _TerrainObject;
    TerrainData _terrain;
       
    [SerializeField]
    Material WaveMat;
    [SerializeField]
    Material Visual;
    [SerializeField]
    Material DetailsWaves;
    public ComputeShader LBMCompute;
    ComputeBuffer bufferInitial;

    ComputeBuffer bufferVelo;
    int kernelHandleClear;
    private RenderTexture outputTexture;
    private RenderTexture HeightTexture;  
    private RenderTexture VelocityTexture;
    private RenderTexture DetailTexture;

    public float viscosity = 0.05f; // Kinematic viscosity
    public float relaxationTime = 0.5f; // Relaxation time
    public float _VelocityCap;
    public float _VelocityS;
    public float _Contrast;
    public float amplitude;
    public float _MaxHeight;
  
    public bool _Bounce;

    //Terrain heightMap texture size
    public int _Height;
    public int _Width;

    [System.Serializable]
    public struct PixelData
    {
        public float n0;
        public float northE;
        public float northW;
        public float northN;
        public float northS;
        public float northNE;
        public float northNW;
        public float northSE;
        public float northSW;
        public float velX;
        public float velY;
        public float rho;
    }

    [System.Serializable]
    public struct VelocityData
    {
        public Vector2 origin;       
    };
   
    //Kernels
    int kernelHandle;   

    int Stream;
    int Tracers;
    private void SetTerrain()
    {
        Visual.SetTexture("_TerrainTex", _terrain.heightmapTexture);
        LBMCompute.SetTexture(kernelHandle, "InputTexture", _terrain.heightmapTexture);
        LBMCompute.SetTexture(Stream, "InputTexture", _terrain.heightmapTexture);
        _MaxHeight = _terrain.size.y;
      
    }
    private void Start()
    {
        TerrainCallbacks.heightmapChanged += heightmapChanged;
        kernelHandle = LBMCompute.FindKernel("CSMain");
       
        Stream = LBMCompute.FindKernel("Stream");
       
        Tracers = LBMCompute.FindKernel("Tracers");
        _terrain = _TerrainObject.terrainData;

        kernelHandleClear = LBMCompute.FindKernel("CSClear");


        outputTexture = new RenderTexture(_Width, _Height, 0, RenderTextureFormat.ARGB32);
        outputTexture.enableRandomWrite = true;
        outputTexture.Create();

        DetailTexture = new RenderTexture(_Width, _Height, 0, RenderTextureFormat.ARGB32);
        DetailTexture.wrapMode = TextureWrapMode.Clamp;
        DetailTexture.filterMode = FilterMode.Bilinear;
        DetailTexture.Create();
        // Create a temporary RenderTexture from the Texture2D to allow read access in the compute shader

        VelocityTexture = new RenderTexture(_Width, _Height, 0, RenderTextureFormat.ARGBFloat);
        VelocityTexture.wrapMode = TextureWrapMode.Clamp;
        VelocityTexture.filterMode = FilterMode.Bilinear;
        VelocityTexture.enableRandomWrite = true;
        VelocityTexture.Create();

        HeightTexture = new RenderTexture(_Width, _Height, 0, RenderTextureFormat.ARGBFloat);
        HeightTexture.enableRandomWrite = true;
        HeightTexture.wrapMode = TextureWrapMode.Clamp;
        HeightTexture.filterMode = FilterMode.Bilinear;
        HeightTexture.Create();

        SetTerrain();

        LBMCompute.SetTexture(kernelHandle, "InputTexture", _terrain.heightmapTexture);
        LBMCompute.SetTexture(kernelHandle, "Velocities", VelocityTexture);

        LBMCompute.SetTexture(Stream, "InputTexture", _terrain.heightmapTexture);     
        LBMCompute.SetTexture(Stream, "Velocities", VelocityTexture);
       
        LBMCompute.SetTexture(kernelHandle, "Result", outputTexture);
        
        LBMCompute.SetTexture(Stream, "Result", outputTexture);
     
        LBMCompute.SetTexture(Tracers, "Velocities", VelocityTexture);
        LBMCompute.SetTexture(Tracers, "HeightTexture", HeightTexture);

        
        LBMCompute.SetTexture(kernelHandleClear, "HeightTexture", HeightTexture);

        PixelData[] initialData = new PixelData[_Width * _Height];
        int size = _Width * _Height;
        // Populate the initial data with values
        for (int i = 0; i < size; i++)
        {
            PixelData pixelData = new PixelData();
            pixelData.n0 = 0f;
            pixelData.northE = 0f;
            pixelData.northW = 0f;
            pixelData.northN = 0f;
            pixelData.northS = 0f;
            pixelData.northNE = 0f;
            pixelData.northNW = 0f;
            pixelData.northSE = 0f;
            pixelData.northSW = 0f;
            pixelData.velX = 0f;
            pixelData.velY = 0f;
            pixelData.rho = 0f;

            initialData[i] = pixelData;
        }
        VelocityData[] initialVel = new VelocityData[256];
      
        // Populate the initial data with values
        for (int i = 0; i < 256; i++)
        {
            VelocityData initialVeldata = new VelocityData();
            initialVeldata.origin = new Vector2(5, i * 2);
          
            initialVel[i] = initialVeldata;
        }
        bufferVelo = new ComputeBuffer(256, sizeof(float) * 2);
        bufferVelo.SetData(initialVel);
        // Pass the buffer to the compute shader
        LBMCompute.SetBuffer(Tracers, "VelocitiesBuffer", bufferVelo);


        // Create the compute buffer
        bufferInitial = new ComputeBuffer(size, sizeof(float) * 12);       
        bufferInitial.SetData(initialData);
        // Pass the buffer to the compute shader
       
        LBMCompute.SetBuffer(kernelHandle, "gridBuffer", bufferInitial);
        

        LBMCompute.SetFloat("viscosity", viscosity);       
        LBMCompute.SetFloat("_VelocityCap", _VelocityCap);       
        LBMCompute.SetFloat("_Contrast", _Contrast);       
        LBMCompute.SetFloat("_RelaxationTime", relaxationTime);      

        LBMCompute.Dispatch(kernelHandle, _Width / 8, _Height / 8, 1);

        LBMCompute.SetBuffer(Stream, "gridBuffer", bufferInitial);

        Visual.SetTexture("_MainTex", outputTexture);       
        Visual.SetTexture("_FlowMap", VelocityTexture);
       
        //WaveMat.SetTexture("_MainTex", VelocityTexture);       
        WaveMat.SetTexture("_NoiseTex", DetailTexture);

    }

    private void heightmapChanged(Terrain terrain, RectInt heightRegion, bool synched)
    {
        Visual.SetTexture("_TerrainTex", _terrain.heightmapTexture);
        LBMCompute.SetTexture(kernelHandle, "InputTexture", _terrain.heightmapTexture);
        LBMCompute.SetTexture(Stream, "InputTexture", _terrain.heightmapTexture);        
    }

   

    private void OnDisable()
    {
        bufferInitial.Dispose();       
        VelocityTexture.Release();
        HeightTexture.Release();
        DetailTexture.Release();

        //TerrainCallbacks.heightmapChanged -= heightmapChanged;
    }
    
    private void Update()
    {
        
        //LBMCompute.Dispatch(kernelHandleClear, _Width / 8, _Height / 8, 1);        
        //LBMCompute.Dispatch(Tracers, 256/64,1, 1);
     

        LBMCompute.Dispatch(Stream, _Width / 8, _Height / 8, 1);
        //Graphics.Blit(VelocityTexture, HeightTexture, Visual);
        Graphics.Blit(null, DetailTexture, Visual);

    }
    private void FixedUpdate()
    {
        LBMCompute.SetFloat("_VelocityCap", _VelocityCap);
        LBMCompute.SetFloat("_Contrast", _Contrast);
        LBMCompute.SetFloat("_RelaxationTime", relaxationTime);
        LBMCompute.SetFloat("viscosity", viscosity);
        LBMCompute.SetFloat("_Height", amplitude / _MaxHeight);
        LBMCompute.SetFloat("_VelocityS", _VelocityS);
        LBMCompute.SetBool("_Bounce", _Bounce);

    }
}


