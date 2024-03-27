Shader "Custom/Visual"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}

        _TerrainTex("_TerrainTex (RGB)", 2D) = "white" {}
        _FlowMap("_FlowMap ", 2D) = "white" {}       
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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "../Shaders/Utils.hlsl"

            struct appdata
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 positionHCS : SV_POSITION;
                float3 viewVector : TEXCOORD1;
                float4 screenPos : TEXCOORD2;
            };


            TEXTURE2D(_MainTex);
            TEXTURE2D(_TerrainTex);
            TEXTURE2D(_FlowMap);
           

            SAMPLER(sampler_MainTex);             
            SAMPLER(sampler_TerrainTex);
            SAMPLER(sampler_FlowMap);
           

            float4 _MainTex_TexelSize;
            float4 _MainTex_ST;
            float4 _FlowMap_ST;
        
            float4 _Color;
             
            ENDHLSL

        Pass
        {
            Name "Terrain"
            Tags
            {
                "Queue" = "Geometry-1"
                "LightMode" = "UniversalForward"

            }

            HLSLPROGRAM
                
         
            v2f vert(appdata v)
            {
                v2f o;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
               
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                float3 positionVS = mul(unity_CameraInvProjection, float4(o.uv * 2 - 1, 0, -1));
                o.viewVector = mul(unity_CameraToWorld, float4(positionVS, 0));
               
                o.screenPos = ComputeScreenPos(o.positionHCS);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                float4 velC = SAMPLE_TEXTURE2D(_FlowMap, sampler_FlowMap, i.uv );                 
               
                return velC.w;
            }
            ENDHLSL
        } 
    }
            
}
