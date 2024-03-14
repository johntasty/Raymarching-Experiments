Shader "Unlit/FluidShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}      
        _SecondTex ("Second Tex", 2D) = "white" {}      
        _ThirdTex ("Third Tex", 2D) = "white" {}      
        _FourthTex ("Fourth Tex", 2D) = "white" {}      

        _Secondary("_Secondary", 2D) = "white" {}
        _MainColor("Main Color", Color) = (1,1,1,1)
        _SecColor("Color", Color) = (1,1,1,1)
        Alias("Alias", Float) = 0
       
    }
    SubShader
    {
            Tags { 
                    "RenderPipeling" = "UniversalPipeline"
                 }
            LOD 100

            HLSLINCLUDE
            #pragma vertex vert
            #pragma fragment frag


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 positionHCS : SV_POSITION;
            };

       
            TEXTURE2D(_MainTex);
            TEXTURE2D(_SecondTex);
            TEXTURE2D(_ThirdTex);
            TEXTURE2D(_FourthTex);

            SAMPLER(sampler_MainTex);
            SAMPLER(sampler_SecondTex);
            SAMPLER(sampler_ThirdTex);
            SAMPLER(sampler_FourthTex);

            float4 _MainTex_TexelSize;
            float4 _MainTex_ST;           
            float4 _MainColor;
            float4 _SecColor;
            float Alias;
            
            ENDHLSL

        Pass
        {
            Name "BOX BLUR"
            Tags
            {
                "Queue" = "Geometry-1"
                "LightMode" = "UniversalForward"
                
            }
           
            HLSLPROGRAM
            
            v2f vert (appdata v)
            {
                v2f o;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
               
                return o;
            }

           
            half4 frag(v2f i) : SV_Target
            {
                float pixel = _MainTex_TexelSize.x;
                float filterStep = pixel / Alias;
                float2 offset = float2(filterStep, 0.);
               
                float4 col1 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);                
                float4 col2 = SAMPLE_TEXTURE2D(_SecondTex, sampler_SecondTex, i.uv);
                float4 col3 = SAMPLE_TEXTURE2D(_ThirdTex, sampler_ThirdTex, i.uv);
                float4 col4 = SAMPLE_TEXTURE2D(_FourthTex, sampler_FourthTex, i.uv);
               /* for (int y = 0; y <= (int)Alias; y++)
                {                    
                    float4 color00 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv - (offset.xx * y));
                    float4 color01 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv - (offset.yx * y));
                    float4 color12 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv - (offset * y));

                    colBlend += color00;
                    colBlend += color01;
                    colBlend += color12;
                }*/
                
                return col1 + col2 + col3 + col4;//float4(colBlend.xyz / ((Alias + 1) * (Alias + 1)), 1.);
            }

                ENDHLSL
        }       

    }

}

