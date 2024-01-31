Shader "HorizontalBlur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}        
        _Samples("Samples", Float) = 0
        _BlurSize("Blur Size", Float) = 0
       
    }
    SubShader
    { 
        Tags
        {
            "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"
        }
       
         HLSLINCLUDE
        #pragma vertex vert
        #pragma fragment frag

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        struct Attributes
        {
            float4 positionOS : POSITION;
            float2 uv : TEXCOORD0;
        };

        struct Varyings
        {
            float4 positionHCS : SV_POSITION;
            float2 uv : TEXCOORD0;
        };

        TEXTURE2D(_MainTex);

        SAMPLER(sampler_MainTex);
        float4 _MainTex_TexelSize;
        float4 _MainTex_ST;

        int _Samples;
        float _BlurSize;

        Varyings vert(Attributes IN)
        {
            Varyings OUT;
            OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
            OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
            return OUT;
        }
        ENDHLSL
        Pass
        {
            Name "BOX BLUR"
            Tags
            {
                "RenderType" = "Opaque"
                "RenderPipeling" = "UniversalPipeline"
                "LightMode" = "UniversalForward"
            }
           
            HLSLPROGRAM
            half4 frag(Varyings IN) : SV_TARGET
            {
                float4 col = 0;
                float invAspect = _ScreenParams.y / _ScreenParams.x;
                for (float index = 0; index < _Samples; index++) {
                    //get uv coordinate of sample
                    float offsetx = (index / (_Samples - 1) - 0.5) * _BlurSize * invAspect;
                    float2 uvx = IN.uv + float2(offsetx, 0);
                    //add color at position to color
                    col += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uvx);
                }
                col = col / _Samples;
                return col;
               
            }
            ENDHLSL
        }       
    }
}
