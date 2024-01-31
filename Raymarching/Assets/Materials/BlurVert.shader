Shader "Unlit/FluidShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}        
        _BlurSize("Blur Size", Float) = 0

        _Amplitude("_Amplitude", Float) = 0
        
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
            SAMPLER(sampler_MainTex);

            float4 _MainTex_TexelSize;
            float4 _MainTex_ST;           

            float _Amplitude;
           
            float _BlurSize;
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

            half4 frag (v2f i) : SV_Target
            {
                
                float3 velAmp = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv).xyz;                
                float4 f45v = float4(0, velAmp.z, sign(velAmp.z) * velAmp.xy);

                for (int j = 1; j <= _BlurSize; j++)
                {
                    float offset = j / float(512.);
                    float4 velAmpL = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + float2(offset, 0));
                    float4 velAmpR = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + float2(-offset, 0));
                    float ampSum = velAmpL.z + velAmpR.z;
                    float ampDif = velAmpL.z - velAmpR.z;
                    float3 f = GetFilter(j / float(_BlurSize));
                   

                    f45v.x += ampDif * f.x * f.y * 2;
                    f45v.y += ampSum * f.x * f.x;

                    f45v.z += (sign(velAmpL.z) * velAmpL.x + sign(velAmpR.z) * velAmpR.x) * f.x;
                    f45v.w += (sign(velAmpL.z) * velAmpL.y + sign(velAmpR.z) * velAmpR.y) * f.x;
                }

                return f45v;
            }

                ENDHLSL
        }       

    }

}

