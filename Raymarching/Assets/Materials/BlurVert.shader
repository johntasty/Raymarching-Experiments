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
            #define MOD2 float2(4.438975,3.972973)
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

            float Hash(float2 p)
               {
                // https://www.shadertoy.com/view/4djSRW - Dave Hoskins
                float2 p2 = frac(p * MOD2);
                p2 += dot(p2.yx, p2.xy + 19.19);
                return frac(p2.x * p2.y);
                //return fract(sin(n)*43758.5453);
            }
            half4 frag(v2f i) : SV_Target
            {
                               
                float4 col1 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);                
                float4 col2 = SAMPLE_TEXTURE2D(_SecondTex, sampler_SecondTex, i.uv);
                float4 col3 = SAMPLE_TEXTURE2D(_ThirdTex, sampler_ThirdTex, i.uv);
                float4 col4 = SAMPLE_TEXTURE2D(_FourthTex, sampler_FourthTex, i.uv);
              
                float4 col = col1 + col2 + col3 + col4;
              
                return col;
            }

                ENDHLSL
        }       

    }

}

