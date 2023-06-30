using System.Collections;
using UnityEngine;

public class LBMTest : MonoBehaviour
{
    [SerializeField]
    Terrain _TerrainObject;
    TerrainData _terrain;

    [SerializeField]
    Material fluidMat;
    [SerializeField]
    Material WaveMat;

    public ComputeShader LBMCompute;
    ComputeBuffer bufferInitial;
   
    private RenderTexture outputTexture;
    private RenderTexture HeightTexture;
    private RenderTexture tempTexture;
    private RenderTexture VelocityTexture;

    
    public float viscosity = 0.05f; // Kinematic viscosity
    public float relaxationTime = 0.5f; // Relaxation time
    public float _VelocityCap;
    public float _Contrast;
    public float amplitude;

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
    public PixelData[] test;

    public struct VelocityData
    {
        public float posX;
        public float posY;
    };
    public VelocityData[] positionsData;

    //Kernels
    int kernelHandle;   
    int Stream;
    int Tracers;
    private void SetTerrain()
    {        
        fluidMat.SetTexture("_TerrainTex", _terrain.heightmapTexture);
        Texture terrain_text = fluidMat.GetTexture("_TerrainTex");
        Graphics.Blit(terrain_text, tempTexture);
    }
    private void Start()
    {
       
        kernelHandle = LBMCompute.FindKernel("CSMain");        
        Stream = LBMCompute.FindKernel("Stream");
       
        Tracers = LBMCompute.FindKernel("Tracers");
        _terrain = _TerrainObject.terrainData;
        
        outputTexture = new RenderTexture(_Width, _Height, 0, RenderTextureFormat.ARGB32);
        outputTexture.enableRandomWrite = true;
        outputTexture.Create();

       
        // Create a temporary RenderTexture from the Texture2D to allow read access in the compute shader
        tempTexture = new RenderTexture(_Width, _Height, 0, RenderTextureFormat.ARGB32);
        tempTexture.enableRandomWrite = true;

        VelocityTexture = new RenderTexture(_Width, _Height, 0, RenderTextureFormat.ARGB32);
        VelocityTexture.enableRandomWrite = true;


        HeightTexture = new RenderTexture(512, 512, 0, RenderTextureFormat.ARGB32);
        HeightTexture.enableRandomWrite = true;
        HeightTexture.wrapMode = TextureWrapMode.Clamp;
        HeightTexture.filterMode = FilterMode.Bilinear;
        HeightTexture.Create();

        SetTerrain();

        LBMCompute.SetTexture(kernelHandle, "InputTexture", tempTexture);
        LBMCompute.SetTexture(kernelHandle, "Velocities", VelocityTexture);

        LBMCompute.SetTexture(Stream, "InputTexture", tempTexture);     
        LBMCompute.SetTexture(Stream, "Velocities", VelocityTexture);
       
        LBMCompute.SetTexture(kernelHandle, "Result", outputTexture);
        LBMCompute.SetTexture(Stream, "Result", outputTexture);
     
        LBMCompute.SetTexture(Tracers, "Velocities", VelocityTexture);
        LBMCompute.SetTexture(Tracers, "HeightTexture", HeightTexture);
       

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
        VelocityData[] initialVel = new VelocityData[64];
        // Populate the initial data with values
        for (int i = 0; i < 64; i++)
        {
            VelocityData initialVeldata = new VelocityData();
            initialVeldata.posX = 0;
            initialVeldata.posY = i * 8;

            initialVel[i] = initialVeldata;
        }
        ComputeBuffer bufferVelo = new ComputeBuffer(64, sizeof(float) * 2);
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
       
        fluidMat.SetTexture("_MainTex", outputTexture);
        WaveMat.SetTexture("_MainTex", outputTexture);
       

    }
    private void OnDisable()
    {
        bufferInitial.Dispose();
        tempTexture.Release();
        VelocityTexture.Release();
        HeightTexture.Release();
    }
    
    private void Update()
    {
        LBMCompute.SetFloat("amplitude", amplitude);
        LBMCompute.Dispatch(Stream, _Width / 8, _Height / 8, 1);
        LBMCompute.Dispatch(Tracers, 1, 64 / 8, 1);
        

        if (Input.GetKey(KeyCode.A))
        {
            LBMCompute.SetFloat("_VelocityCap", _VelocityCap);
            LBMCompute.SetFloat("_Contrast", _Contrast);
            
            SetTerrain();

        }

    }
   
}
