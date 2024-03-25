Shader "Unlit/VerticalBlur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Secondary ("_Secondary", 2D) = "white" {}
        
        _BlurSize("Blur Size", Float) = 0
        dxScale("dx Scale", Range(-2.,2.)) = 0
        dyScale("dy Scale", Range(-2.,2.)) = 0
        _Power("_Power", Float) = 0
        _Base("Base Height", Float) = 0
        HW("HW", Float) = 0

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

            float _BlurSize;
            float dxScale;
            float dyScale;
            float _Power;
            float _Base;
            float HW;
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
            float4 RGBToGrayscale(float4 color)
            {
                float luminance = dot(color.rgb, float3(0.299, 0.587, 0.114));
                return float4(luminance, luminance, luminance, color.a);
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
            half4 frag(v2f i) : SV_Target
            {
                float texSize = HW;
                
                float3 f123 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv).xyz; // x:f_1 y:f_2 z:f_3 (times amplitude)
                float4 f45v = SAMPLE_TEXTURE2D(_Secondary, sampler_Secondary, i.uv); // x:f_4 y:f_5 z:velX w:velY
                float4 deviation = float4(f45v.x, 0, f123.x, 1); // initialize deviation at this pixel
                float4 gradient = float4(f123.y, 0, 0, 1); // initialize gradient at this pixel
                float2 gradCorr = float2(f123.z, f45v.y); // initialize gradient correction
                float4 velocity = float4(f123.z, -0.5f * f45v.y, 0, 1); // initialize velocity at this pixel
                float2 dir = f45v.zw; // average direction

                float4 col = float4(0, 0, 0, 1);
                for (int j = 1; j <= (int)_BlurSize; j++)
                {
                    float offset = j / texSize;

                    float4 f123B = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + float2(0, -offset));
                    float4 f123T = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + float2(0, offset));

                    float4 f45vB = SAMPLE_TEXTURE2D(_Secondary,sampler_Secondary, i.uv + float2(0, -offset));
                    //f45vB.zw *= 2. - 1.;
                    float4 f45vT = SAMPLE_TEXTURE2D(_Secondary, sampler_Secondary, i.uv + float2(0, offset));
                    //f45vT.zw *= 2. - 1.;
                    float3 f = GetFilter(j / float(_BlurSize));

                    
                    deviation.x += (f45vB.x + f45vT.x) * f.x * f.x; // deviation X
                    deviation.y += (f45vB.y - f45vT.y) * 2 * f.x * f.y; // deviation Y
                    deviation.z += (f123B.x + f123T.x) * f.x; // deviation Z

                    gradient.x += (f123B.y + f123T.y) * f.x; // gradient X
                    gradient.y += (f123B.x - f123T.x) * f.y; // gradient Y

                    gradCorr.x += (f123B.z + f123T.z) * f.x * f.x; // gradient X horizontal deviation
                    gradCorr.y += (f45vB.y + f45vT.y) * f.z; // gradient Y horizontal deviation    

                    dir += (f45vB.zw  + f45vT.zw ) * f.x; // average direction


                }
                gradCorr *= PI / _BlurSize;
                gradient.xy *= (PI / _BlurSize) / (1 + gradCorr);
                           
                dir = normalize(dir); // average propagation direction              
                dir = dir * 2. - 1.;
                deviation.x *= (dir.x);
                deviation.y *= (dir.y);
                
               
                float coll = (-deviation.x - deviation.y + deviation.z);
                return  (coll * _Power) + _Base;
                                
                
                
            }
            ENDHLSL
                            
        }
    }
}
