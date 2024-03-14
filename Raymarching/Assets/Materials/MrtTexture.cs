using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MrtTexture : MonoBehaviour
{
    public RenderBuffer[] _mrt;

    public RenderTexture DetailTexture;
    public RenderTexture WaveTexture;

    public Material BlurV;
    public Material Outs;
    // Start is called before the first frame update
    private void OnEnable()
    {
        _mrt = new RenderBuffer[2];
    }
    void OnDisable()
    {
        DetailTexture.Release();
        WaveTexture.Release();
        _mrt = null;
    }
    void Start()
    {
        DetailTexture = new RenderTexture(512, 512, 0, RenderTextureFormat.Default);
        WaveTexture = new RenderTexture(512, 512, 0, RenderTextureFormat.Default);

        WaveTexture.Create();
        DetailTexture.Create();

        _mrt[0] = DetailTexture.colorBuffer;
        _mrt[1] = WaveTexture.colorBuffer;
        Graphics.SetRenderTarget(_mrt, DetailTexture.depthBuffer);
        Graphics.Blit(null, BlurV, 0);

        // Combine them and output to the destination.
        Outs.SetTexture("_MainTex", DetailTexture);
        Outs.SetTexture("_Secondary", WaveTexture);
        

    }

    // Update is called once per frame
    void Update()
    {
        Graphics.SetRenderTarget(_mrt, DetailTexture.depthBuffer);
        //Graphics.Blit(null, BlurV, 0);
    }
}
