Shader "Unlit/FluidShaderHorizontal"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Secondary ("_Secondary", 2D) = "white" {}
         _MainColor("Main Color", Color) = (1,1,1,1)
        _BlurSize("Blur Size", Float) = 0
        _Power("Power", Range(0.,10.)) = 0
        
        _Smooth("Smooth", Range(0.,10.)) = 0

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
            TEXTURE2D(_Secondary);
            SAMPLER(sampler_MainTex);
            SAMPLER(sampler_Secondary);
            float4 _MainTex_TexelSize;
            float4 _MainTex_ST;
            float4 _Secondary_ST;
            float4 _MainColor;

            float _BlurSize;
            float _Power;           
            float _Smooth;
            ENDHLSL
                       
        Pass
        {
            Name "BOX BLURH"
            Tags
            {
                "Queue" = "Geometry"
                
            }            
           
            HLSLPROGRAM

            v2f vert(appdata v)
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
            half4 frag(v2f i) : SV_Target
            {

                float4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
               /* float4 f123 = float4(velAmp.z, 0, 0.5 * velAmp.z, 1);

               for (int j = 1; j <= _BlurSize; j++)
               {
                   float offset = j / float(512.);
                   float4 velAmpL = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + float2(offset, 0));
                   float4 velAmpR = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + float2(-offset, 0));
                   float ampSum = velAmpL.z + velAmpR.z;
                   float ampDif = velAmpL.z - velAmpR.z;
                   float3 f = GetFilter(j / float(_BlurSize));
                   f123.x += ampSum * f.x;
                   f123.y += ampDif * f.y;
                   f123.z += ampSum * f.z;

               }

               return f123;*/

               // float4 accumulatedColor = color;
               //
               // for (int j = -_BlurSize; j <= _BlurSize; j++)
               // {
               //     for (int k = -_BlurSize; k <= _BlurSize; k++)
               //     {
               //         // Calculate the current sample position
               //         float2 offset = float2(j, k) / 512.;
               //         float2 samplePos = i.uv + offset;
               //                                 
               //         accumulatedColor += (SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, samplePos));
               //        
               //     }
               // }
               // accumulatedColor /= (_BlurSize * _BlurSize);
               //return accumulatedColor;

               int numSamples = _BlurSize * 2.;

               //// Initialize accumulated color
               float4 accumulatedColor = _MainColor;
               float totalWeight = 0;
               float texel = _BlurSize / 512.;
               for (int j = -_BlurSize; j <= _BlurSize; j++)
               {
                   // Calculate the current sample position
                   float offset = j / 512.;
                   float2 samplePos = i.uv + float2(0, offset);

                   // Calculate the distance to the center
                   float2 distance = i.uv - samplePos;
                   float distanceSqr = sqrt(distance.x * distance.x + distance.y * distance.y);
                   // If the sample is inside the circular region, accumulate its color
                   if (distanceSqr <= texel)
                   {
                       // Calculate the weight based on the distance
                       float weight = 1 - saturate((distanceSqr * _Smooth) / (texel));

                       accumulatedColor += (SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, samplePos)) * weight;

                       totalWeight += weight;
                   }
                   /*for (int k = -_BlurSize; k <= _BlurSize; k++)
                   {

                   }*/
               }


               // Calculate the final blurred color by averaging the accumulated color
               float4 finalColor = accumulatedColor / totalWeight;
               return finalColor * _Power;
            }
            ENDHLSL
                            
        }
    }
}
