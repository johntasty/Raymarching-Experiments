using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ParticleWaves : MonoBehaviour
{
    public ComputeShader ParticleWavesCompute;
    public Material WavesShader;

    public float speed;
    public float gradient;
    public float size;

    private RenderTexture outputTexture;
    ComputeBuffer bufferVelo;
    int kernelHandle;
   
    public struct Particle
    {
        public float posX;
        public float posY;
    };
    public Particle[] _ParticleData;
    // Start is called before the first frame update
    void Start()
    {

        outputTexture = new RenderTexture(512, 512, 0, RenderTextureFormat.ARGB32);
        outputTexture.enableRandomWrite = true;
        outputTexture.wrapMode = TextureWrapMode.Clamp;
        outputTexture.filterMode = FilterMode.Bilinear;
        outputTexture.Create();

        ParticleWavesCompute.SetTexture(kernelHandle, "Result", outputTexture);

        Particle[] initialVel = new Particle[64];
        // Populate the initial data with values
        for (int i = 0; i < 64; i++)
        {
            Particle initialVeldata = new Particle();
            initialVeldata.posX = 0;
            initialVeldata.posY = i * 8 + 4;

            initialVel[i] = initialVeldata;
        }
        bufferVelo = new ComputeBuffer(64, sizeof(float) * 2);
        bufferVelo.SetData(initialVel);
        // Pass the buffer to the compute shader
        ParticleWavesCompute.SetBuffer(kernelHandle, "ParticlesBuffer", bufferVelo);


        ParticleWavesCompute.SetFloat("speed", speed);
       
        WavesShader.SetTexture("_MainTex", outputTexture);
    }
    private void OnDisable()
    {
        outputTexture.Release();
        //bufferVelo.Dispose();
    }
    // Update is called once per frame
    void Update()
    {
        
        ParticleWavesCompute.SetFloat("_Time", Time.deltaTime);
        ParticleWavesCompute.SetFloat("speed", speed);       
        ParticleWavesCompute.SetFloat("gradient", gradient);       
        ParticleWavesCompute.SetFloat("size", size);       
        ParticleWavesCompute.SetFloat("smooth", size);       
        ParticleWavesCompute.Dispatch(kernelHandle, 512/8, 512 / 8, 1);
    }
}
