Shader "Unlit/FluidShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}        
        _Mask ("_Mask", 2D) = "white" {}      
        _MainColor("Main Color", Color) = (1,1,1,1)
        _SecColor("Color", Color) = (1,1,1,1)
        _BlurSize("Blur Size", Float) = 0
        _Smooth("Smooth", Float) = 0

        DRAG_MULT ("DRAG_MULT", Range(0.,.5)) = 0.048
        Rand("Rand", Float) = 0.048
        Depth ("Depth", Range(0.,20.)) = 0.048
        Frequency("Frequency", Range(1.,2.)) = 1.1
        Weight("Weight", Range(0.,1.)) = .5
        Speed("Speed", Range(0.,2.)) = .5
        Time("Time", Range(1.,2.)) = 1.1
        Iterations ("Iterations", Int) = 16

        _Size("Size", Range(0.,1.)) = 0.
             
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
            TEXTURE2D(_Mask);
            SAMPLER(sampler_MainTex);
            SAMPLER(sampler_Mask);

            float _MainTex_TexelSize;
            float4 _MainTex_ST;           
            float4 _MainColor;
            float4 _SecColor;

            float _BlurSize;
            float _Size;
            float _Smooth;

            float DRAG_MULT;
            float Depth;
            float Frequency;
            float Speed;
            float Weight;
            float Time;
            int Iterations;
            float Rand;
            
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
            
            v2f vert (appdata v, const uint instance_id : SV_InstanceID)
            {
                v2f o;
               
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
               
                return o;
            }
           
            float3 GetFilter(in float v)
            {
                float s, c;
                sincos(PI * v, s, c);
                return float3(
                0.5f * (c + 1.0f), // 0.5 ( cos(v) + 1 )
                -0.5f * s, // -0.5 sin(v)
                -0.25f * (c * c - s * s + c) // cos(2v) + cos(v)
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
            float2 wavedx(float2 position, float2 direction, float speed,float frequency, float timeshift) {
              float x = dot(direction, position) * frequency + timeshift * speed;
              float wave = exp(sin(x) - 2.);
              float dx = wave * cos(x);
              return float2(wave, -dx);
            }

           float getwaves(float2 position, int iterations) {
              float iter = 0.0; // this will help generating well distributed wave directions
              float frequency = 2.0; // frequency of the wave, this will change every iteration
              float speed = 1.0;
              float timeMultiplier = 2.0; // time multiplier for the wave, this will change every iteration
              float weight = 1.;// weight in final sum for the wave, this will change every iteration
              float sumOfValues = 0.0; // will store final sum of values
              float sumOfWeights = 0.0; // will store final sum of weights


              for (int i = 0; i < iterations; i++) {
                  // generate some wave direction that looks kind of random
                  float2 p = float2(sin(Hash(-iter)), cos(Hash(iter)));
                  // calculate wave data
                  float2 res = wavedx(position, p, speed, frequency, _Time.y * timeMultiplier);
            
                  // shift position around according to wave drag and derivative of the wave
                  position += p * res.y * weight * DRAG_MULT;
            
                  // add the results to sums
                  sumOfValues += res.x * weight;
                  sumOfWeights += weight;
            
                  // modify next octave parameters
                  weight *= Weight;
                  frequency *= Frequency;
                  timeMultiplier *= Time;
                  speed *= Speed;
            
                  // add some kind of random value to make next wave look random too
                  iter += Hash(Rand);
                }
              // calculate and return
              return sumOfValues / sumOfWeights;
           }

      
            half4 frag(v2f i) : SV_Target
            {


                /* int p = 0;
                 float2 pos = float2(512, 512);
                 float _offset = 0;

                 float4 f123 = float4(color.z, 0, 0.5 * color.z, 1);

                 for (int j = 1; j <= _BlurSize; j++)
                 {
                     float off = (float)j / 512.;
                     float4 velAmpL = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + float2(off, 0));
                     float4 velAmpR = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + float2(-off, 0));
                     float ampSum = velAmpL.z + velAmpR.z;
                     float ampDif = velAmpL.z - velAmpR.z;
                     float3 f = GetFilter(j / float(_BlurSize));
                     f123.x += ampSum * f.x;
                     f123.y += ampDif * f.y;
                     f123.z += ampSum * f.z;

                 }

                 return f123;*/

                
                // float4 accumulatedColor = _MainColor;
                // float totalWeight = 0;
                // float texel = _BlurSize / 512.;
                // for (int j = -_BlurSize; j <= _BlurSize; j++)
                // {
                //     for (int k = -_BlurSize; k <= _BlurSize; k++)
                //     {
                //         // Calculate the current sample position
                //         float2 offset = float2(j, k) / 512.;
                //         float2 samplePos = i.uv + offset;

                //         // Calculate the distance to the center
                //         float2 distance = i.uv - samplePos;
                //         float distanceSqr = sqrt(distance.x * distance.x + distance.y * distance.y);
                //         // If the sample is inside the circular region, accumulate its color
                //         if (distanceSqr <= _BlurSize / 512.)
                //         {
                //             // Calculate the weight based on the distance
                //             float weight = 1 - saturate((distanceSqr * _Size) / (_BlurSize / 512.));

                //             accumulatedColor += (SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, samplePos)) * weight;

                //             totalWeight += weight;
                //         }
                //     }
                // }

                //// Calculate the final blurred color by averaging the accumulated color
                //float4 finalColor = accumulatedColor / totalWeight;
                float2 ex = float2(0.01, 0);
                
                float y = getwaves(i.uv, Iterations) * Depth;
                /*float x = (getwaves(i.uv - ex.xy, Iterations) * Depth);
                float z = (getwaves(i.uv + ex.yx, Iterations) * Depth);*/
                float3 col = float3(y, y, y);
               
                return float4(col,1.0);
                //return finalColor * _Smooth;
            }

                ENDHLSL
        }       

    }

}

