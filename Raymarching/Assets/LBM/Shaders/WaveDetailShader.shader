Shader "Unlit/WaveDetailShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}        
       
        DRAG_MULT ("DRAG_MULT", Range(0.,1.)) = 0.048
        Denom("Denom", Range(0.,128.)) = 0.048
        Rand("Rand", Float) = 0.048
        DetailIter("Detail Iterations", Int) = 8
        Depth ("Depth", Range(0.,1.)) = 0.048
        Detail("Detail", Range(0.,512.)) = 0.048
        Frequency("Frequency", Range(0.,300.)) = 1.1
        FrequencyAdd("FrequencyAdd", Range(0.,100.)) = 1.1
        Weight("Weight", Range(0.,32.)) = .5
        Speed("Speed", Range(0.,2.)) = .5
        ScrollSpeed("Scroll Speed", Range(0.,50.)) = .5       
        Iterations ("Iterations", Int) = 16
        _Power("_Power", Float) = 16
         
       
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
           
            float DRAG_MULT;
            float Denom;
            float Depth;
            float Detail;
            float Frequency;
            float FrequencyAdd;
            float Speed;
            float ScrollSpeed;
            float Weight;           
            int Iterations;
            int DetailIter;
            float _Power;
           
          

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
            
            v2f vert (appdata v, const uint instance_id : SV_InstanceID)
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
          
            float4 hash43(float3 p)
            {
                float4 p4 = frac(float4(p.xyzx) * HASHSCALE4);
                p4 += dot(p4, p4.wzxy + 19.19);
                return frac((p4.xxyz + p4.yzzw) * p4.zywx);
            }
            float drip(float2 uv, float2 pos, float age, float scale, float cells) {
                float2 vD = float2(uv - pos);
                float fD = sqrt(dot(vD, vD)) * 2.0 * (cells / Denom);
                float fDa = FrequencyAdd * fD;
                float freq = Frequency * scale;
                return    max(0.0, 1.0 - fDa * fDa)
                        * sin((fD * freq - age * ScrollSpeed * (scale * 2.0 - 1.0)) * DRAG_MULT);

            }
            float drops(float2 uv, float cells) {
                float height = 0.0;
                float2 cell = floor(uv * cells);
                for (int iter = 0; iter < Iterations; iter++) {
                    for (int i = -1; i <= 1; i++) {
                      for (int j = -1; j <= 1; j++) {
                        float2 cell_t = cell + float2(i, j);
                        float2 uv_t = uv;
            
                        float4 rnd_t = hash43(float3(cell_t, float(iter)));
                        float2 pos_t = (cell_t + rnd_t.xy) / cells;
                        float age_t = (_Time.y * Speed + rnd_t.z);
                        float scale_t = rnd_t.w;
                        height += drip(uv_t, pos_t, age_t, scale_t, cells);
                      }
                    }
                }
                return height;
            }
            float heightmap(float2 uv) {
                float height = 0.0;
                
                height += drops(uv, Detail);
                for (int i = 2; i < DetailIter; i+=2)
                {
                    height += drops(uv, Detail / i);
                    
                }               
                height /= Weight;
                return height * Depth;
            }
           
            half4 frag(v2f i) : SV_Target
            {               
                float height = (heightmap(i.uv)) *.5 + .5;
               
                return float4(height, height, height, 1.0) * _Power;
            }

                ENDHLSL
        }       

    }

}

