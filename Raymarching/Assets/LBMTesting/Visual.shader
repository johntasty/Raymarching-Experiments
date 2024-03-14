Shader "Custom/Visual"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}

        _TerrainTex("_TerrainTex (RGB)", 2D) = "white" {}
        _FlowMap("_FlowMap ", 2D) = "white" {}
        _HeightMap("_HeightMap ", 2D) = "white" {}
        _Base("_Base ", 2D) = "white" {}
        _Noise("_Noise ", 2D) = "white" {}

        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0

        _FlowSpeed("Flow speed", Float) = 1.0
        _FlowTileScale("Flow tile scale", Float) = 35.0
        _heightTileScale("Height tile scale", Float) = 35.0
        _Force("Force", Float) = 35.0
        _FluidDis("FluidDis", Float) = 35.0
        _FluidVelocity("Fluid Velocity", Range(0.001,.03)) = 0.25
        _FluidVelocityY("Fluid Velocity Y", Range(-1.,1.)) = 0.25
        _UJump("U jump per phase", Range(-0.25, 0.25)) = 0.25
        _VJump("V jump per phase", Range(-0.25, 0.25)) = 0.25
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
                #include "../Materials/Utils.hlsl"

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
                TEXTURE2D(_HeightMap);
                TEXTURE2D(_Base);
                TEXTURE2D(_Noise);

                SAMPLER(sampler_MainTex);             
                SAMPLER(sampler_TerrainTex);
                SAMPLER(sampler_FlowMap);
                SAMPLER(sampler_HeightMap);
                SAMPLER(sampler_Base);
                SAMPLER(sampler_Noise);

                float4 _MainTex_TexelSize;
                float4 _MainTex_ST;
                float4 _FlowMap_ST;
            
                float4 _Color;

                float _FlowSpeed;
                float _FlowTileScale;
                float _heightTileScale;
                float _Force;
                float _UJump;
                float _VJump;
                float _FluidDis;
                float _FluidVelocity;
                float _FluidVelocityY;
              
                #define PI  3.1415927

                 
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
                float3 cells(float2 uv, float2 flowVector, float time, float2 jump,float flowOffset,float tiling, bool flowB)
                {
                    float phaseOffset = flowB ? 0.5 : 0;
                    float progress = frac(time + phaseOffset);
                    float3 uvw;
                    uvw.xy = uv - flowVector * progress;
                    uvw.xy *= tiling;
                    uvw.xy += phaseOffset;
                    uvw.xy += (time - progress) * jump;
                    uvw.z = 1 - abs(1 - 2 * progress);

                    return uvw;
                }
               
                half4 frag(v2f i) : SV_Target
                {
                    float4 velC = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                    float colBlend2 = SAMPLE_TEXTURE2D(_TerrainTex, sampler_TerrainTex, i.uv).r * 2.;
                    float4 flow = SAMPLE_TEXTURE2D(_FlowMap, sampler_FlowMap, i.uv) ;
                    float cSpeed = sqrt(flow.x * flow.x + flow.y * flow.y);
                    flow.xy *= _Force;

                    float noise = SAMPLE_TEXTURE2D(_Noise, sampler_Noise, i.uv).a;
                    float time = _Time.y * _FlowSpeed + noise;
                    float2 jump = float2(_UJump, _VJump);
                    float3 gd  = cells(i.uv,flow.xy, time, jump, _heightTileScale, _FlowTileScale, false);
                    float3 gd1 = cells(i.uv,flow.xy, time, jump, _heightTileScale, _FlowTileScale, true);
                    

                    float4 col1 = SAMPLE_TEXTURE2D(_Base, sampler_Base, gd.xy)  * gd.z;
                    float4 col2 = SAMPLE_TEXTURE2D(_Base, sampler_Base, gd1.xy) * gd1.z;

                                     
                   
                    float2 off = float2(_FluidVelocity, 0.) * .5;

                    float speedR = (SAMPLE_TEXTURE2D(_FlowMap, sampler_FlowMap, i.uv + off).y);
                    float speedL = (SAMPLE_TEXTURE2D(_FlowMap, sampler_FlowMap, i.uv - off).y);
                    float speedU = (SAMPLE_TEXTURE2D(_FlowMap, sampler_FlowMap, i.uv + off.yx).x);
                    float speedD = (SAMPLE_TEXTURE2D(_FlowMap, sampler_FlowMap, i.uv - off.yx).x);
                    float col = abs(speedR - speedL - speedU + speedD) * _FluidDis;
                   
                    return (col1 + col2) * col;
                }

                    ENDHLSL
            }

        }
}
