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
   
    [System.Serializable]
    public struct Particle
    {
        public float posX;
        public float posY;
        public Vector2 origin;
    };
    public Particle[] _ParticleData;
    // Start is called before the first frame update
    void Start()
    {

        outputTexture = new RenderTexture(512, 512, 0, RenderTextureFormat.ARGB32);
        outputTexture.enableRandomWrite = true;
        //outputTexture.wrapMode = TextureWrapMode.Clamp;
        //outputTexture.filterMode = FilterMode.Bilinear;
        outputTexture.Create();

        ParticleWavesCompute.SetTexture(kernelHandle, "Result", outputTexture);

        _ParticleData = new Particle[64];
        // Populate the initial data with values
        for (int i = 0; i < 64; i++)
        {
           
            float angle = (float)i / 64f * Mathf.PI * 2f;            
            float radius = 20f; // Adjust the radius as desired

            Particle initialVeldata = new Particle();
            //initialVeldata.posX = 256 + Mathf.Cos(angle) * radius;
            //initialVeldata.posY = 256 + Mathf.Sin(angle) * radius;
            initialVeldata.posX = 256;
            initialVeldata.posY = i * 8;
            //Vector2 direction = new Vector2(initialVeldata.posX, initialVeldata.posY) - new Vector2(256,256);
            //float angleDisperse = Mathf.Atan2(direction.y, direction.x);
            initialVeldata.origin = new Vector2(0, i * 8);

            _ParticleData[i] = initialVeldata;
        }
        bufferVelo = new ComputeBuffer(64, sizeof(float) * 4);
        bufferVelo.SetData(_ParticleData);
        // Pass the buffer to the compute shader
        ParticleWavesCompute.SetBuffer(kernelHandle, "ParticlesBuffer", bufferVelo);


        ParticleWavesCompute.SetFloat("speed", speed);
        
        WavesShader.SetTexture("_MainTex", outputTexture);
    }
    private void OnDisable()
    {
        outputTexture.Release();
        bufferVelo.Dispose();
    }
    // Update is called once per frame
    void Update()
    {

        ParticleWavesCompute.SetFloat("_Time", Time.deltaTime);
        ParticleWavesCompute.SetFloat("speed", speed);
        //ParticleWavesCompute.SetFloat("gradient", gradient);       
        //ParticleWavesCompute.SetFloat("size", size);       
        //ParticleWavesCompute.SetFloat("smooth", size);       
        ParticleWavesCompute.Dispatch(kernelHandle, 1, 64 / 8, 1);
    }
}
