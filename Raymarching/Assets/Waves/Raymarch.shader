Shader "Unlit/RayMarch"
{
    Properties
    {

         [MainTexture] _MainTex("Texture", 2D) = "white" {}
        _NoiseTex("Noise Texture", 2D) = "white" {}

        _BaseColor("Sky Color", Color) = (0, 0, 0.5, 0.3)        
        _BaseColor2("Sky2 Color", Color) = (0, 0, 0.5, 0.3)    
        _SecondaryColor("Depth Color", Color) = (0, 0, 0.5, 0.3)
        _ScatterColor("Scatter Color", Color) = (0, 0, 0.5, 0.3)
        _SpecullarColor("Specullar Color", Color) = (0, 0, 0.5, 0.3)
        _WaterColor("Water Color", Color) = (0, 0, 0.5, 0.3)

        _BaseBrightness("Base Brightness", Float) = 0
        _SecondaryBrightness("Depth Brightness", Float) = 0
        _ScatterBrightness("Scatter Brightness", Float) = 0       
        _WaterBrightness("Water Brightness", Float) = 0

        _Fresnel("Fresnel Power", Float) = 0     
        _SunSpec("SunSpec Power", Float) = 0
            
        _FresnelSize("Fresnel Size", Float) = 1.0
        _DepthSize("Depth Size", Float) = 1.0
        _ColorHeightStart("Depth Height Start", Float) = 1.0

         LightIntenSity("Light IntenSity", Float) = 0.
        _Metallic("Metallic", Range(0.0, 1.)) = 0.0
        _Roughness("_Roughness", Range(0.0, 10.)) = 0.5
        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5

        _Max_Steps("_Max_Steps", Float) = 100.0
        _Max_Distance("_Max_Distance", Float) = 100.0

        _Accuracy("_Accuracy", Float) = 0.001
                   
        _Bounds("Bounds", Vector) = (0,0,0)     
        _Offset("Offset", Vector) = (0,0,0)
      
        HEIGHT_FACTOR("HEIGHT", Float) = 0.5
        _WaterLevel("_WaterLevel", Float) = 0.5
        freq("Tilling", Float) = 0.5
     
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
        float4 _BaseColor2;
        float _BaseBrightness;

        float4 _SecondaryColor;
        float _SecondaryBrightness;

        half4 _SpecullarColor;
       
        half4 _ScatterColor;
        float _ScatterBrightness;

        half4 _WaterColor;
        float _WaterBrightness;

        float _Fresnel;        
        
        float _SunSpec;
    
       
        half _FresnelSize;
        half _DepthSize;
        half _ColorHeightStart;
       
        half _Smoothness;
        half _Roughness;
        half _Metallic;

        uniform half _Max_Steps;
        uniform half _Max_Distance;
        uniform half _Accuracy;
      
        uniform half HEIGHT_FACTOR;
     
        half LightIntenSity;

        half4 _Bounds;       
        half _WaterLevel;
        half4 _Offset;       
    
       
        float freq = 0.5;

        #define PI 3.14159265359
           
           
        // Box intersection by IQ https://iquilezles.org/articles/boxfunctions
        float2 boxIntersection(in float3 ro, in float3 rd, in float3 rad, float depth, out float3 oN)
        {
            ro -= unity_ObjectToWorld._m03_m13_m23;
            float3 m = 1.0 / rd;
            float3 n = m * ro;
            float3 k = abs(m) * rad;
            float3 t1 = -n - k;
            float3 t2 = -n + k;

            float tN = max(max(t1.x, t1.y), t1.z);
            float tF = min(min(t2.x, t2.y), t2.z);

            if (tN > tF || tF < 0.0 || tN > depth) return float2(-1.0, -1.0); // no intersection

            oN = -sign(rd) * step(t1.yzx, t1.xyz) * step(t1.zxy, t1.xyz);

            return float2(tN, tF);
        }

        float _HeightMap(float3 p)
        {
            float2 uv = (p.xz * freq) + _Offset.xy;
            //float h = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, uv ).r * _Offset.z;
            float h2 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv ).r * _Offset.w;

            /*h2 -= 1.;
            h2 /= 5.;
            h2 *= (_WaterLevel + 1.);*/

            float sum = (h2 ) * HEIGHT_FACTOR ;
            return sum ;
        }
       
        float3 _GetNormalH(float3 pos, float dis)
        {         
            const float eps = 0.005 * dis;
            const float3 h = float3(eps, 0,0);
            return normalize(float3(_HeightMap(pos - h.xyz) - _HeightMap(pos + h.xyz),
                2. * eps,
                _HeightMap(pos - h.yzx) - _HeightMap(pos + h.yzx)));

        }
        float4 _DepthColor(float3 pos)
        {
            half depth = _DepthSize + pos.y;
            float4 col = depth * _SecondaryBrightness * _SecondaryColor;
            return col;
        }
       
        float Saturate(float value) {
            return clamp(value, 0, 1);
        }

        float diffuse(float NdL) {
            //float LdotN = Saturate(_WaterBrightness * NdL);
            return 1. / PI;
        }
        float3 specularHighlight(float NdL, float NdV, float NdH) {
            //cook-torrance
            float metallic = _Metallic * _Metallic;
            float metallic2 = metallic * metallic;
            float norm = 2.0 / metallic2 - 2.0;
            float spec = (norm + 2.0) / (2. * PI) * pow(NdH, norm);

            //shlick aproxx
            float k = metallic * .5;
            float Vi = NdV * (1. - k) + k;
            float Len = NdL * (1. - k) + k;
            float sch = .25 / (Vi / Len);

            float rim = lerp(1. - _Metallic, 1., NdV);
            float speccular = max((1. / rim) * sch * spec, 0.0);

            return speccular * _SpecullarColor;

        }
        half3 SkyColors(float3 rayDirection) {
            Light lights = GetMainLight();

            float LdotV = dot(rayDirection, lights.direction);
            float area = _SunSpec;

            float Halopow = clamp((1. + LdotV) / 2., 0.0, 2.0);
            float3 lightHalo = float3(Halopow, Halopow, Halopow);

            lightHalo = pow(lightHalo, _BaseColor.rgb * _SecondaryBrightness) * lights.color;
            float3 col = area * lights.color * _SunSpec;

            col *= 3. * lightHalo * _ScatterColor;

           
            return col;
          
        }
        half3 _SubssurfaceScat(float3 pos, float3 normal, float3 ray, float3 light)
        {
            float3 scatterColor = _ScatterColor * _ScatterBrightness; 
            float3 rayDir = normalize(ray - pos);
            float angle = dot(rayDir, normal);

            float ss_po = max(0.0, acos(dot(rayDir, light)));
            ss_po = smoothstep(1., PI, ss_po);
            ss_po = pow(ss_po * angle, 3.);

            half3 ssColor = scatterColor * pos.y * ss_po * 100.;
            return ssColor * .8 * 250 * 0.005;
        }
        half3 _Shading(float3 pos, float3 rayD,float3 normal, float specular, float dist, float3 ro) 
        {
            Light lights = GetMainLight();
            normal = lerp(normal, float3(0.0, 1.0, 0.0), _Smoothness * min(1.0, sqrt(dist * 0.01) * _Roughness));
            float3 sunDir = normalize((lights.direction));

            float3 view = -rayD;
            float3 HalfV = normalize(view + sunDir);

            float NdL = dot(normal, sunDir);
            float NdV = dot(normal, view);
            float NdH = dot(normal, HalfV);
            float HdV = max(0.001, dot(HalfV, view));

            float2 uv = (pos.xz * _NoiseTex_ST.z) + _NoiseTex_ST.xy;
            float3 h2 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, uv);

            /*float fresnel = 1.0 - max(dot(normal, -rayD), 0.0);
            fresnel = pow(fresnel, _FresnelSize) * _Fresnel;*/
          
            float3 fres = lerp(_WaterColor, float3(1, 1, 1), pow(1. - HdV, _Fresnel));
            //float3 reflected = SkyColors(reflect(rayD, normal)) * _BaseBrightness;
            float3 specc = float3(specularHighlight(NdL, NdV, NdH)) * NdL;
            float3 diffuseCol = (float3(1,1,1) - fres) * diffuse(NdL) * NdL;
           
            float3 Lightcolor = float3(0.0, 0., 0.0);
            float3 DiffsueLight = float3(0.0, 0., 0.0);


            float reflectionR = dot(reflect(rayD, normal), sunDir);
            Lightcolor += specc * _BaseColor * _BaseBrightness * LightIntenSity;
            DiffsueLight += diffuseCol * _BaseColor * _BaseBrightness * LightIntenSity;


            float fres2 = lerp(_WaterColor, float3(1, 1, 1), pow(1. - NdV, _Fresnel));
            Lightcolor += min(float3(.99, .99, .99), fres2) * reflectionR;
            DiffsueLight += _BaseColor2 * (1. / PI);

            

            //specular                 
            float3 color = DiffsueLight * (_WaterColor);
            color += Lightcolor;
                     
            color += _SubssurfaceScat(pos, normal, ro, sunDir);
            //depth
            float atten = max(1.0 - dist * 0.001, 0.0);
            color += _WaterColor * (pos.y - _ColorHeightStart);
            //color += h2 * _SunSpec;
            return  color;
        }
       
        v2f vert(appdata v)
        {
            v2f o = (v2f)0;
            VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
            //o.uv = UnityStereoTransformScreenSpaceTex(v.uv);
            o.uv = TRANSFORM_TEX(v.uv, _MainTex);
            o.ro = TransformWorldToObject(GetCameraPositionWS());
            o.roWS = GetCameraPositionWS();
            o.hitPos = TransformObjectToWorld(v.vertex.xyz);

            o.vertex = TransformObjectToHClip(v.vertex);
            o.screenPos = ComputeScreenPos(o.vertex);

            float3 PositionWS = TransformObjectToWorld(v.vertex.xyz);
            o.positionWS = TransformWorldToView(PositionWS);
            o.viewVectorWS = _WorldSpaceCameraPos - PositionWS;

            float3 viewVectors = mul(unity_CameraInvProjection, float4(o.uv * 2 - 1, 0, -1));
            o.viewVector = TransformWorldToObject(mul(unity_CameraToWorld, float4(viewVectors, 0)));

            return o;
        }

     

        half4 frag(v2f i) : SV_Target
        {
            float2 screenuvs = (i.screenPos.xy / i.screenPos.w);
            float depthZ = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, screenuvs);
            float nonLinear = LinearEyeDepth(depthZ, _ZBufferParams);

            float3 viewSpaceForwardDir = mul(float3 (0, 0, -1), (float3x3)UNITY_MATRIX_V);

            half3 ro = _WorldSpaceCameraPos;
            half3 rd = normalize(i.hitPos - ro);

            float div = dot(rd, viewSpaceForwardDir);
            nonLinear /= div;

            half3 color = half3(0, 0, 0);
            float3 n;
            float2 result = boxIntersection(ro, rd, _Bounds.xyz, nonLinear, n);
            
            if (result.x > 0.0) {

                float3 position = ro + rd * result.x;
                float3 heightHit;
                float3 heightNormal;
                float tt = result.x;
                float2 hh = _HeightMap(position);
                float spec;
                if (position.y < hh.x)
                {
                    heightNormal = n;
                    heightHit = _DepthColor(position);
                }
                else
                {
                    float3 p = float3(0, 0, 0);
                    float h = _Accuracy * 2.;
                    UNITY_LOOP
                    for (int j = 0; j < _Max_Steps; j++)
                    {
                        p = ro + rd * tt;
                        h = p.y - _HeightMap(p).x;
                        if (h < _Accuracy || tt > result.y || tt >= nonLinear || tt > _Max_Distance)
                            break;
                                               
                        tt += h * .4;
                    }
                                       
                    float dist = distance(ro + rd * tt, ro);
                   
                    heightNormal = _GetNormalH(ro + rd * tt, tt);
                    heightHit = _Shading(ro + rd * tt, rd, heightNormal, spec, dist, ro);
                                                        
                                        
                }              
             
                if (tt > result.y || tt >= nonLinear)
                {
                    clip(-1);
                   
                }
                return float4(heightHit, 1);
              
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
