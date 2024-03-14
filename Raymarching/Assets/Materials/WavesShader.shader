Shader "Unlit/WavesShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}        
        _Mask ("_Mask", 2D) = "white" {}      
        _MainColor("Main Color", Color) = (1,1,1,1)
        _SecColor("Color", Color) = (1,1,1,1)
        _BlurSize("Blur Size", Float) = 0
        _Amlpitude("Amlpitude", Float) = 0
        _WaveSize("_WaveSize", Float) = 0
        HW("HW", Float) = 0
        //DRAG_MULTWave("DRAG_MULT_Wave", Range(0.,1.)) = 0.048
        //DenomWave("Denom_Wave", Float) = 0.048
        //Rand("Rand", Float) = 0.048        
        //DepthWave("Depth_Wave", Range(0.,50.)) = 0.048
        //DetailWave("Detail_Wave", Range(0.,20.)) = 0.048
        //FrequencyWave("Frequency_Wave", Range(0.,20.)) = 1.1
        //FrequencyAddWave("FrequencyAdd_Wave", Range(0.,20.)) = 1.1
        //WeightWave("Weight_Wave", Range(0.,1.)) = .5
        //SpeedWave("Speed_Wave", Range(0.,2.)) = .5
        //ScrollSpeedWave("Scroll Speed_Wave", Range(0.,2.)) = .5
        //Time("Time_Wave", Range(1.,2.)) = 1.1
        //IterationsWave("Iterations_Wave", Int) = 16

        _Size("Size", Range(0,1)) = 0.
             
    }
    SubShader
    {
            Tags { 
                    "RenderPipeling" = "UniversalPipeline"
                 }
            LOD 100
            //Blend SrcColor One
            HLSLINCLUDE
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

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
            struct f2f
            {
                float4 color01 : COLOR0;
                float4 color02 : COLOR1;
               
            };
           
            TEXTURE2D(_MainTex);
            TEXTURE2D(_Mask);
            SAMPLER(sampler_MainTex);
            SAMPLER(sampler_Mask);

            float4 _MainTex_TexelSize;
            float4 _MainTex_ST;           
            float4 _MainColor;
            float4 _SecColor;

            float _BlurSize;
            float _Size;
            float _Amlpitude;
            float _WaveSize;
            float HW;
                                  
            
            /*float Time;
            float Rand;
            float DRAG_MULTWave;
            float DepthWave;
            float DenomWave;
            float DetailWave;
            float FrequencyWave;
            float FrequencyAddWave;
            float SpeedWave;
            float ScrollSpeedWave;
            float WeightWave;
            int IterationsWave;*/

            #define MOD2 float2(4.438975,3.972973)
            #define HASHSCALE4 float4(1031, .1030, .0973, .1099)
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
            float3 GetFilter(float v)
            {
                float s, c;
                sincos(PI * v, s, c);
                return float3(
                    0.5 * (c + 1.0), // 0.5 ( cos(v) + 1 )
                    0.5 * (c - 1.), // -0.5 sin(v)
                    -0.5 * (c * c - s * s + c) // cos(2v) + cos(v)
                );
            }
            float4 RGBToGrayscale(float4 color)
            {
                float luminance = dot(color.rgb, float3(0.299, 0.587, 0.114));
                return float4(luminance, luminance, luminance, color.a);
            }
            float Hash(float p)
               {
                // https://www.shadertoy.com/view/4djSRW - Dave Hoskins
                float2 p2 = frac(float2(p,p) * MOD2);
                p2 += dot(p2.yx, p2.xy + 19.19);
                return frac(p2.x * p2.y);
                //return fract(sin(n)*43758.5453);
            }
            float2x2 rotation(float vec)
            {
                float2x2 matr = float2x2(cos(vec), sin(vec), -sin(vec), cos(vec));
                return matr;
            }

            v2f vert (appdata v)
            {
                v2f o;
               
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                               
                return o;
            }
           
         
            f2f frag(v2f i) : SV_Target
            {
                 f2f o;
                                 
                 float4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);

                 float4 f123 = float4(tex.z, 0, 0.5 * tex.z, 1);               
                 float4 f45v = float4(0, tex.z, tex.xy);
                 float4 col = float4(0, 0, 0, 1);
               
                 float offset = 1. / HW;
                 float off = 0.;
                 for (int y = 1; y <= (int)_BlurSize; y++)
                 {
                     
                     off += offset;
                     float4 texL = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + float2(off, 0));
                     float4 texR = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + float2(-off, 0));
                    
                     float ampSum = texL.z + texR.z;
                     float ampDif = texL.z - texR.z;

                     float3 f = GetFilter(y / float(_BlurSize));
                     f123.x += ampSum * f.x;
                     //col.x += ampSum * f.x;
                     f123.y += ampDif * f.y;
                     //col.y += ampDif * f.y;
                     f123.z += ampSum * f.z;
                     //col.z += ampSum * f.z;
                     f45v.x += ampDif * f.x * f.y * 2;
                     f45v.y += ampSum * f.x * f.x;

                     f45v.z += texL.x + texR.x * f.x;
                     f45v.w += texL.y + texR.y * f.x;
                 }
                
                 o.color01 = f123;
                 o.color02 = f45v;
                 return o;


                
            }

                ENDHLSL
        }       

    }

}

