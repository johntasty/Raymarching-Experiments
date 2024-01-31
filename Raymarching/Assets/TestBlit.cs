using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TestBlit : MonoBehaviour
{
    public Material pass1;
    public Material pass2;

    public Texture ground;

    // Start is called before the first frame update
    void Start()
    {

       

    }

    // Update is called once per frame
    void FixedUpdate()
    {
        RenderTexture outputTexture = RenderTexture.GetTemporary(512, 512, 0, RenderTextureFormat.ARGBHalf);        
        Graphics.Blit(ground, outputTexture, pass1);
       
        
        RenderTexture horizontalBlurTexture = RenderTexture.GetTemporary(512, 512, 0, RenderTextureFormat.ARGBHalf);
        Graphics.Blit(outputTexture, horizontalBlurTexture, pass2);

        RenderTexture.ReleaseTemporary(outputTexture);
        RenderTexture.ReleaseTemporary(horizontalBlurTexture);
        // Apply the final blurred texture to the object's material
        pass2.SetTexture("_MainTex", horizontalBlurTexture);
    }
}
