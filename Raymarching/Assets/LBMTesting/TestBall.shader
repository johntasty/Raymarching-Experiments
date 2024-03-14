Shader "Custom/Visual"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
       
        _Foam("_Foam ", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
      
        DDxSize("DDxSize", Range(0,1)) = 6.
        DDxTile("DDxTile", Float) = 6.
        Force("Force", Float) = 6.
        Test("Test", Float) = 6.
        Bounds("Bounds", Vector) = (0,0,0,0)
      
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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                struct appdata
                {
                    float4 positionOS : POSITION;
                    float2 uv : TEXCOORD0;
                };

                struct v2f
                {
                    float2 uv : TEXCOORD0;
                    float4 positionHCS : SV_POSITION;
                    float3 positionWS : TEXCOORD1;
                    float3 positionOS : TEXCOORD2;
                    float3 rayOrigin : TEXCOORD4;
                    float3 viewVector : TEXCOORD5;
                    float4 screenPos : TEXCOORD3;
                    
                };


                TEXTURE2D(_MainTex);
                TEXTURE2D(_TerrainTex);
                TEXTURE2D(_Tracers);
                TEXTURE2D(_Foam);
                TEXTURE2D(_Noise);
                SAMPLER(sampler_MainTex);
                SAMPLER(sampler_Foam);
                SAMPLER(sampler_Noise);
                SAMPLER(sampler_TerrainTex);
                SAMPLER(sampler_Tracers);

                float4 _MainTex_TexelSize;
                float4 _MainTex_ST;
                float4 Bounds;
                float4 _Color;
               
                float DDxSize;
                float DDxTile;
                float Force;
                float Test;
               
                #define PI  3.1415927

                 
                ENDHLSL

            Pass
            {
                ZWrite On ZTest Always
                Name "Terrain"
                Tags
                {
                    "Queue" = "Geometry-1"
                    "LightMode" = "UniversalForward"

                }

                HLSLPROGRAM
                    

               float _Ball(float3 pos)
               {
                    float3 q = abs(pos - unity_ObjectToWorld._m03_m13_m23 - half3(0,Test,0)) - Bounds;
                    
                    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);

                    
               }
               float2 boxIntersection(in float3 ro, in float3 rd, in float3 rad, in float depth,out float3 oN)
               {
                    //rd *= normalize(unity_ObjectToWorld._m03_m13_m23);
                    ro -= unity_ObjectToWorld._m03_m13_m23;
                    //ro.y -= Test;
                    float3 m = 1.0 / rd;
                    float3 n = m * ro;
                    float3 k = abs(m ) * rad ;
                    float3 t1 = -n - k;
                    float3 t2 = -n + k;

                    float tN = max(max(t1.x, t1.y), t1.z);
                    float tF = min(min(t2.x, t2.y), t2.z);

                    if (tN > tF || tF < 0.0 || tN > depth ) return float2(-1.0, -1.0); // no intersection

                    oN = -sign(rd) * step(t1.yzx, t1.xyz) * step(t1.zxy, t1.xyz);

                    return float2(tN, tF);
               }
               float3 normal(float3 p)
               {

                    half2 e = half2(0.001, 0);
                    half3 n = half3(
                        _Ball(p + e.xyy) - _Ball(p - e.xyy),
                        _Ball(p + e.yxy) - _Ball(p - e.yxy),
                        _Ball(p + e.yyx) - _Ball(p - e.yyx));
                    return normalize(n);
               }
               v2f vert(appdata v)
               {
                   v2f o;                   
                   o.positionWS  = TransformObjectToWorld(v.positionOS.xyz);
                   o.positionHCS = TransformWorldToHClip(o.positionWS.xyz);
                   o.positionOS  = v.positionOS.xyz;
                   o.rayOrigin = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1));

                   o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                 
                   o.screenPos = ComputeScreenPos(o.positionHCS);
                   float3 viewVector = mul(unity_CameraInvProjection, float4(o.screenPos.xy / o.screenPos.w , 0, -1));
                   o.viewVector = mul(unity_CameraToWorld, float4(viewVector, 0));
                 
                   return o;
               }
               float _March(float3 rayOrg, float3 rayDir, float depth)
               {

                    float t = 0.;
                    float dis;
                    
                    UNITY_LOOP
                    for (int i = 0; i < 65; i++)
                    {
                        //if (t > 0.01) break;
                        float3 p = rayOrg + t * rayDir;
                        if (depth < t)break;
                        dis = _Ball(p);
                        t += dis;
                       
                        if (dis < Force || t > Bounds.w) {break; }


                    }
                    return t;
               }
               float _HeightMap(float3 p)
               {
                    float2 uv = (p.xz * _MainTex_ST.z) + _MainTex_ST.xy;
                    float h2 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv).r * _MainTex_ST.w;
                    float sum = (h2) * DDxTile ;
                    return sum - .1;
               }
               float3 _GetNormalH(float3 pos, float dis)
               {
                   const float eps = 0.001 * dis;
                   const float3 h = float3(eps, 0,0);
                   return normalize(float3(_HeightMap(pos - h.xyz) - _HeightMap(pos + h.xyz),
                       2. * eps,
                       _HeightMap(pos - h.yzx) - _HeightMap(pos + h.yzx)));

               }
               half4 frag(v2f i) : SV_Target
               {
                    Light lights = GetMainLight();

                    float2 screenuvs = (i.screenPos.xy / i.screenPos.w);                   
                    float depthZ = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, screenuvs);
                    float sceneZ = LinearEyeDepth(depthZ, _ZBufferParams);

                    float3 viewSpaceForwardDir = mul(float3 (0, 0, -1), (float3x3)UNITY_MATRIX_V);
                   
                    half3 ro = _WorldSpaceCameraPos;
                    half3 rd = normalize(i.positionWS - ro);

                    float div = dot(rd, viewSpaceForwardDir);
                    sceneZ /= div;

                    half4 col = float4(0, 0, 0, 1);
                    float3 n;
                    float2 result = boxIntersection(ro, rd, Bounds.xyz, sceneZ, n);
                    if (result.x > 0.) {
                        half3 colHit;
                        colHit = n;
                        float3 position = ro + rd * result.x;
                     
                        float height = _HeightMap(position);
                        float tt = result.x;
                        
                        if (position.y  < height )
                        {
                            colHit = n;
                        }
                        else {

                            float3 p = float3(0, 0, 0);
                            float h = Force * 2.;
                            UNITY_LOOP
                            for (int j = 0; j < 75; j++)
                            {
                                p = ro + rd * tt;
                                h = p.y - _HeightMap(p).x;                                
                                if (h < Force || tt >= sceneZ || tt > Bounds.w || tt > result.y)
                                    break;      
                                tt += h * .4;
                            }
                                                       

                            colHit = _Color * dot(lights.direction, _GetNormalH(p, tt));// _GetNormalH(ro + rd * tt);
                        }
                        if (tt > result.y || tt >= sceneZ)
                        {
                            clip(-1);
                        }
                       
                        return half4(colHit, 1);
                    }
                    clip(-1.);
                    return col;
                   
               }

                    ENDHLSL
            }

        }
}
