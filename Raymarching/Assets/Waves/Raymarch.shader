Shader "Unlit/RayMarch"
{
    Properties
    {

         [MainTexture] _MainTex("Texture", 2D) = "white" {}
        _NoiseTex("Noise Texture", 2D) = "white" {}
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

        _GridResolution("Grid Resolution", Float) = 10
        _Bounds("Bounds", Vector) = (0,0,0)
        _Base("_Base", Vector) = (0,0,0)
        _Offset("Offset", Vector) = (0,0,0)
      
        _Smooth("_Smooth", Float) = 0.
        size("Tilling", Vector) = (0,0,0)
        _FlowSpeed("Flow Speed", Float) = 0.
        _WaveLen("_WaveLen Speed", Float) = 0.
        HEIGHT_FACTOR("HEIGHT", Float) = 0.5
     
    }
        HLSLINCLUDE

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
        TEXTURE2D(_NoiseTex);
        SAMPLER(sampler_MainTex);
        SAMPLER(sampler_NoiseTex);
        float4 _MainTex_ST;
        float4 _NoiseTex_ST;

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
        half _FlowSpeed;

        half4 _Bounds;       
        half4 _Base;
        half4 _Offset;       
        half _Smooth;
        half _WaveLen;
        half _GridResolution;
        const float freq = 0.5f;
           
        float2 FlowUV(float2 uv, float2 flowVector, float time) {
            
            return uv - flowVector ;
        }
            
        float2 rotateUV(float2 uv, float2 direction)
        {
            // Normalize the direction vector
            direction = normalize(direction);

            // Calculate the rotation matrix
            float2x2 rotationMatrix = float2x2(
                direction.x, -direction.y,
                direction.y, direction.x
            );

            // Rotate the UV coordinates
            return mul(float2x2(direction.x, -direction.y, direction.y, direction.x), uv);
        }
        
        // loads noise texture and turns it into flowmap
        float2 flowTex(float2 uv) {
            
            float4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv );
            float2 flowMap = tex.xy * _WaveLen;
            
            return flowMap; // constant bias scale for -1 to 1 range
        }
        // Box intersection by IQ https://iquilezles.org/articles/boxfunctions
        float2 boxIntersection(in float3 ro, in float3 rd, in float3 rad, out float3 oN)
        {
            float3 m = 1.0 / rd;
            float3 n = m * ro;
            float3 k = abs(m) * rad;
            float3 t1 = -n - k;
            float3 t2 = -n + k;

            float tN = max(max(t1.x, t1.y), t1.z);
            float tF = min(min(t2.x, t2.y), t2.z);

            if (tN > tF || tF < 0.0) return float2(-1.0, -1.0); // no intersection

            oN = -sign(rd) * step(t1.yzx, t1.xyz) * step(t1.zxy, t1.xyz);

            return float2(tN, tF);
        }

        float2 _HeightMap(float3 p)
        {
            float2 uv = (p.xz + _Offset.xy);
            float h = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, uv).rg * HEIGHT_FACTOR;
            return h;
        }
        float3 _GetNormalH(float3 pos)
        {
            /*float d = 2 / _Smooth;
            float hMid = _HeightMap(pos);
            float hRight = _HeightMap(pos + float3(d, 0, 0));
            float hTop = _HeightMap(pos + float3(0, 0, d));
            return normalize(cross(float3(0, hTop - hMid, d), float3(d, hRight - hMid, 0)));*/

            float3 n;
            float d = 0.01;
            n.y = _HeightMap(pos);
            n.x = _HeightMap(float3(pos.x + d, pos.y, pos.z)) - n.y;
            n.z = _HeightMap(float3(pos.x, pos.y, pos.z + d)) - n.y;
            n.y = d;
            return normalize(n);
        }
       
       
        float Saturate(float value) {
            return clamp(value, 0, 1);
        }

        float diffuse(float3 normal, float3 light, float dis) {
            return pow(dot(normal, light) * _WaterBrightness + 0.6, dis);
        }
        float3 specularHighlight(half3 normal, half3 light, half3 direction, float distance) {
            float3 refl = reflect(direction, normal);
            float LdotV = dot(refl, light);
            float surface = _SpecullarBrightness;
            float sun = smoothstep(surface, 0., 1. - LdotV);
            return _SpecullarColor * sun * 0.01 / surface;

           /* float nrm = (distance + 8.0) / (3.1415 * 8.0);
            float spec = pow(max(dot(reflect(direction, normal), light), 0.0), distance) * nrm;
            return float3(spec, spec, spec);*/
        }
        half3 SkyColors(half3 rayDirection) {
            rayDirection.y = max(rayDirection.y, 0.0);
            float3 col = float3(0, 0, 0);
            col.x = pow(1.0 - rayDirection.y, 2.0);
            col.y = 1.0 - rayDirection.y;
            col.z = .6 + (1.0 - rayDirection.y)* _BaseBrightness;
            return col * _SecondaryBrightness;
          
        }
        half3 _Shading(float3 pos, float3 rayD,float3 normal, float specular, float dist) 
        {
            Light lights = GetMainLight();
            normal = lerp(normal, float3(0.0, 1.0, 0.0), _Smoothness * min(1.0, sqrt(dist * 0.01) * _Roughness));
            half3 sunDir = normalize(lights.direction);
            float3 color = float3(0, 0, 0);

            float fresnel = 1.0 - max(dot(normal, -rayD), 0.0);
            fresnel = pow(fresnel, _FresnelSize) * _Fresnel;
          
            float3 reflected = SkyColors(reflect(rayD, normal));
            float3 refracted = _Base + diffuse(normal, sunDir, _SunSpec) * _WaterColor * _WaterBrightness;

            color = lerp(refracted, reflected, fresnel);

            float atten = max(1.0 - dist * 0.001, 0.0);
            color += _WaterColor * (pos.y - _DepthSize) * 0.18 * atten;

            color += float3(specularHighlight(normal, sunDir, rayD, _SpecullarBrightness));
                       
            return float3(specularHighlight(normal, sunDir, rayD, _SpecullarBrightness));
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

                   
            
          
            half3 color = half3(0, 0, 0);
            float3 n;
            float2 result = boxIntersection(ro, rd, _Bounds.xyz, n);
            
            if (result.x > 0.0) {

                float3 position = ro + rd * result.x;
                float3 heightHit;
                float3 heightNormal;
                float tt = result.x;
                float2 h = _HeightMap(position);
                float spec;
                if (position.y < h.x)
                {
                    heightNormal = _SecondaryColor;
                    heightHit = _SecondaryColor;
                }
                else
                {
                    float3 p = ro + rd * tt;
                    UNITY_LOOP
                    for (int i = 0; i < _Max_Steps; i++)
                    {
                        p = ro + rd * tt;
                        float h = p.y - _HeightMap(p).x;
                        if (h < _Accuracy || tt > result.y)
                            break;
                        if (tt > _Max_Distance)  break;
                        tt += h * 0.4;
                    }
                    heightNormal = _GetNormalH(ro + rd * tt);
                    float dist = distance(p , ro);
                    heightHit = _Shading(ro + rd * tt, rd, heightNormal, spec, dist);
                }              
             
                if (tt > result.y)
                {
                    clip(-1);
                   
                }
                return half4(heightHit, 1);
              
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
                //Blend SrcAlpha OneMinusSrcAlpha
                HLSLPROGRAM
                // Signal this shader requires a compute buffer
                #pragma prefer_hlslcc gles
                #pragma exclude_renderers d3d11_9x
                #pragma target 5.0

                // Lighting and shadow keywords
                //#pragma shader_feature_local_fragment _SURFACE_TYPE_TRANSPARENT
                //#pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON
                #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
                #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
                #pragma multi_compile _ _ADDITIONAL_LIGHTS
                #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
                #pragma multi_compile _ _SHADOWS_SOFT
               
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
