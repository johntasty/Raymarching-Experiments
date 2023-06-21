Shader "Unlit/RayMarch"
{
    Properties
    {

         [MainTexture] _MainTex("Texture", 2D) = "white" {}
        _BaseColor("Base Color", Color) = (0, 0, 0.5, 0.3)        
        _BaseBrightness("Base Brightness", Float) = 0

        _SecondaryColor("Secondary Color", Color) = (0, 0, 0.5, 0.3)
        _SecondaryBrightness("Secondary Brightness", Float) = 0

        _ScatterColor("Scatter Color", Color) = (0, 0, 0.5, 0.3)
        _ScatterBrightness("Scatter Brightness", Float) = 0

        _SpecullarColor("Specullar Color", Color) = (0, 0, 0.5, 0.3)
        _SpecullarBrightness("Specullar Brightness", Float) = 0

        _WaterColor("Water Color", Color) = (0, 0, 0.5, 0.3)
        _WaterBrightness("Water Brightness", Float) = 0

        _Fresnel("Fresnel Power", Float) = 0
        _RefractPower("_Refract Power", Float) = 0
        _ScatteringPower("_Scattering Power", Float) = 0
        _SunSpec("SunSpec Power", Float) = 0
            
        _FresnelSize("Fresnel Size", Float) = 1.0
        _DepthSize("Depth Size", Float) = 1.0
        _ColorHeightStart("Depth Height Start", Float) = 1.0
        _WaterColorClamp("Water Color Clamp", Float) = 1.0
      

        _Metallic("Metallic", Range(0.0, 5.0)) = 0.0
        _Roughness("_Roughness", Range(0.0, 10.)) = 0.5
        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5

        _Max_Steps("_Max_Steps", Float) = 100.0
        _Max_Distance("_Max_Distance", Float) = 100.0

        _Accuracy("_Accuracy", Float) = 0.001

        _Bounds("Bounds", Vector) = (0,0,0)
        _Offset("Offset", Vector) = (0,0,0)
      
        _Smooth("_Smooth", Float) = 0.
        size("Tilling", Vector) = (0,0,0)
        HEIGHT_FACTOR("HEIGHT", Float) = 0.5
     
    }
        HLSLINCLUDE
#pragma vertex vert
#pragma fragment frag
            // make fog work
#pragma multi_compile_fog

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"


            struct appdata
        {
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;
            half4 color : COLOR;

        };

        struct v2f
        {
            float2 uv : TEXCOORD0;
            half3 positionWS               : TEXCOORD1;
            half3 ro     : TEXCOORD3;
            half3 roWS     : TEXCOORD2;
            half3 hitPos : TEXCOORD4;
            half4 screenPos : TEXCOORD5;
            half3 viewVector : TEXCOORD6;
            half3 viewVectorWS : TEXCOORD7;
            half4 color : COLOR;
            float4 vertex : SV_POSITION;
        };
        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        float4 _MainTex_ST;

        float4 _BaseColor;
        float _BaseBrightness;

        float4 _SecondaryColor;
        float _SecondaryBrightness;

        half4 _SpecullarColor;
        float _SpecullarBrightness;

        half4 _ScatterColor;
        float _ScatterBrightness;

        half4 _WaterColor;
        float _WaterBrightness;

        float _Fresnel;        
        
        float _SunSpec;
    
        float _RefractPower;
        float _ScatteringPower;

        half _FresnelSize;
        half _DepthSize;
        half _ColorHeightStart;
        half _WaterColorClamp;

        half _Smoothness;
        half _Roughness;
        half _Metallic;

        uniform half _Max_Steps;
        uniform half _Max_Distance;
        uniform half _Accuracy;
      
        uniform half HEIGHT_FACTOR;
        half2 size;

        half4 _Bounds;       
        half4 _Offset;       
        half _Smooth;
        
       
        // Box intersection by IQ https://iquilezles.org/articles/boxfunctions

        float2 boxIntersection(float3 ro, float3 rd)
        {
            float3 oN = 0;
            float3 m = 1.0 / rd;
            float3 n = m * ro;
            float3 k = abs(m) * _Bounds.xyz;
            float3 t1 = -n - k;
            float3 t2 = -n + k;

            float tN = max(max(t1.x, t1.y), t1.z);
            float tF = min(min(t2.x, t2.y), t2.z);

            if (tN > tF || tF < 0.0) return float2(-1.0, -1.0); // no intersection

            oN = -sign(rd) * step(t1.yzx, t1.xyz) * step(t1.zxy, t1.xyz);

            return float2(tN, tF);
        }
    
        float sdBox(float3 p)
        {
            const float g = sin(atan2(1., 2));
            float3 q = abs(p) - _Bounds.xyz;
            float2 uv = size * (p.xz + _Offset.xy);

          /*  uv = uv * 1024 + 0.5;

            float2 iuv = floor(uv);
            float2 fuv = frac(uv);
            uv = iuv + fuv * fuv * (3.0 - 2.0 * fuv);
            uv = (uv - 0.5) / 1024;*/

            //uv.y += _Time.y * .1;
            
            float h =  SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex,  uv).r;
            h *= HEIGHT_FACTOR;

            q.y -= h;
            q.y *= g;
            return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
            
        }
        float map(float3 pos) {
                   
            return sdBox(pos);
          
        }
        float3 getNormal(float3 pos)
        {    
            // Tetrahedral normal, IQ.
            float eps = 1 / _Smooth;
            float2 e = float2(eps, -eps);
            return normalize(
                e.xyy * map(pos + e.xyy) +
                e.yyx * map(pos + e.yyx) +
                e.yxy * map(pos + e.yxy) +
                e.xxx * map(pos + e.xxx));
          
        }
        float Saturate(float value) {
            return clamp(value, 0, 1);
        }
      
        float specularHighlight(half3 n, half3 l, half3 e, float s) {
            float nrm = (s + 8.0) / (3.1415 * 8.0);
            return pow(max(dot(reflect(e, n), l), 0.0), s) * nrm;
        }
        half3 SkyColors(half3 rayDirection) {
            float rad = _FresnelSize;
            half3 col = half3(0,0,0);

            half3 sc = (_BaseColor * _BaseBrightness) * _Smoothness;
            float a = length(rayDirection.xy);
            col += rad / (rad + pow(a, _Roughness)) * sc;
            col = col + lerp(col, _SecondaryColor * _SecondaryBrightness, Saturate(1.0 - length(col))) * _DepthSize;
            col += .05  * sc;

            return (col);
        }
      
        float2 RayMarchNoise(half3 rayOrigin, half3 rayDir) {
          
            float d;
            float2 result = float2(-1, -1);
          
            UNITY_LOOP
            for (int i = 0; i < _Max_Steps; i++) {
                float3 ray = rayOrigin + rayDir * d;
                float sd = map(ray);
                result = float2(d, d);      
                if (ray.y < -_Bounds.y) result = float2(-1, -1);
                if (sd < _Accuracy) {                    
                    break;
                }
                d += sd;
                if (d > _Max_Distance)  break;
            }
           
            if (d > _Max_Distance) result = float2(-1, -1);
            return result;
        }
      
        v2f vert(appdata v)
        {
            v2f o = (v2f)0;
            VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
            o.uv = UnityStereoTransformScreenSpaceTex(v.uv);
           
            o.ro = TransformWorldToObject(GetCameraPositionWS());
            o.roWS = GetCameraPositionWS();
            o.hitPos = v.vertex.xyz;

            o.vertex = TransformObjectToHClip(v.vertex);
            o.screenPos = ComputeScreenPos(v.vertex);

            o.positionWS = mul(unity_ObjectToWorld, v.vertex);
            o.viewVectorWS = GetWorldSpaceViewDir(GetCameraPositionWS());

            float3 viewVectors = mul(unity_CameraInvProjection, float4(v.uv * 2 - 1, 0, -1));
            o.viewVector = mul(unity_CameraToWorld, float4(viewVectors, 0));

            return o;
        }

     

        half4 frag(v2f i) : SV_Target
        {
            half3 ro = i.ro;
          
            half3 direction = i.hitPos;
            half3 rd = normalize(direction - ro);
            float2 screenUV = i.screenPos.xy / i.screenPos.w;

            float viewDir = length(i.viewVector);
            float nonLinear = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.uv);
            float sceneEyeDepthtest = LinearEyeDepth(nonLinear, _ZBufferParams) * viewDir;

                   
            Light lights = GetMainLight();
            float2 box = RayMarchNoise(ro, rd);
            half3 color = half3(0, 0, 0);
            if (box.x > -.5) {

                float3 position = ro + box.y * rd;
               
                half3 normals = getNormal(position);
                half3 refl = reflect(rd, normals);
                refl.y = abs(refl.y);
                half3 refrac = refract(rd, normals, 1. / _RefractPower);

                float fresnel = clamp((pow(1. - max(0.0, dot(-normals, rd)), _Fresnel)), 0.0, 1.0);
                half3 sunDir = lights.direction;

                color += SkyColors(refl) * fresnel;

                float Scattering = pow(max(0.0, dot(refrac, sunDir)), _ScatteringPower);
               
                color += pow(_WaterColor * _WaterBrightness, 2) * Scattering;

                half3 waterColor = (_ScatterColor * _ScatterBrightness) * pow(min(position.y * _ColorHeightStart, _WaterColorClamp), 4.);
                color += waterColor;

                half3 specularHigh = specularHighlight(normals, sunDir, rd, _SunSpec) * .2;
                color += specularHigh * (_SpecullarColor * _SpecullarBrightness);
                return half4(color, 1);
              
            }
            clip(-1);
            return half4(0,0,0,1);//half4(color * (1.0 - result.w) + result.xyz * result.w, 1.0);

        }
            ENDHLSL

            SubShader {
            // UniversalPipeline needed to have this render in URP
            Tags{ "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" }

                // Forward Lit Pass
                Pass
            {
                Name "ForwardLit"
                Tags { "LightMode" = "UniversalForward" }

                ZWrite On
                Blend SrcAlpha OneMinusSrcAlpha
                HLSLPROGRAM
                // Signal this shader requires a compute buffer
                #pragma prefer_hlslcc gles
                #pragma exclude_renderers d3d11_9x
                #pragma target 5.0

                // Lighting and shadow keywords
                #pragma shader_feature_local_fragment _SURFACE_TYPE_TRANSPARENT
                #pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON
                #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
                #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
                #pragma multi_compile _ _ADDITIONAL_LIGHTS
                #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
                #pragma multi_compile _ _SHADOWS_SOFT
                #pragma multi_compile_fog
                #pragma shader_feature FADE
                #pragma multi_compile_instancing
                // Register our functions
                #pragma vertex vert
                #pragma fragment frag

                // Include vertex and fragment functions

                ENDHLSL
            }
        }
}
