Shader "Unlit/NoiseWave"
{
    Properties
    {

        [MainTexture] _MainTex("Albedo", 2D) = "white" {}
        _BaseColor("Color", Color) = (0, 0, 0.5, 0.3)
        _FirstColor("_FirstColor", Color) = (0, 0, 0.5, 0.3)
        _SecondColor("_SecondColor", Color) = (0, 0, 0.5, 0.3)
     
         _SpecColorSize("_SpecColorSize", Float) = 1.0
        _SpecPower("_SpecPower", Float) = 1.0
        _SpecPowerPreClamp("_SpecPowerPreClamp", Float) = 50.0
            _Reflections("_Reflections", Range(0.0, 1.0)) = .5
        [HDR]_SpecColor("Specular", Color) = (0.2, 0.2, 0.2)

        _EmmisionSize("EmmisionSize", Float) = 1.0
        [HDR] _EmissionColor("Color", Color) = (0,0,0)

        
        _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
        _Roughness("_Roughness", Range(0.0, 10.)) = 0.5
        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5
        
        

        _ShadowMin("_ShadowMin Distance", Float) = 0.1
        _ShadowMax("_ShadowMax_Distance", Float) = 100.0
        _ShadowIntensity("_ShadowIntensity", Float) = 5.0
        _ShadowPenumbra("_ShadowPenumbra", Float) = 5.0

        _Max_Steps("_Max_Steps", Float) = 100.0
        _Max_Distance("_Max_Distance", Float) = 100.0
 
        _Accuracy("_Accuracy", Float) = 0.001
        _Max("_Max", Float) = 0.001
        _MaxMinus("_MaxMinus", Float) = 0.001

        _Bounds("Bounds", Vector) = (0,0,0)
        _WaveOrigin("_WaveOrigin", Vector) = (0,0,0)
        _WaveOrigin2("_WaveOrigin2", Vector) = (0,0,0)
        _Origin("_Origin", Vector) = (0,0,0)
        _Smooth("_Smooth", Float) = 0.
        _Height("_Height", Float) = 0.
        _WaveSmoothing("_WaveSmoothing", Float) = 0.
     
        meanFrequency("meanFrequency", Float) = .6
        baseSpeed("baseSpeed", Float) = 7.
        averageAmplitude("averageAmplitude", Float) = 0.2
        numberOfWaves("numberOfWaves", Float) = 16.
        _SphereSmooth("_SphereSmooth", Float) = 16.

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
        //GetAbsolutePositionWS(input.positionWS)
        float4 _MainTex_ST;
        float4 _BaseColor;
        float4 _FirstColor;
        float4 _SecondColor;
            //shading
        half4 _SpecColor;
        half4 _EmissionColor;
        half4 _LightColor;

        half _Reflections;
        half _SpecColorSize;
        half _EmmisionSize;

        half _Smoothness;
        half _Roughness;
        half _Metallic;
        half _SpecPower;
        half _SpecPowerPreClamp;

        half _ShadowMin;
        half _ShadowMax;
        half _ShadowIntensity;
        half _ShadowPenumbra;

        uniform half _Max_Steps;
        uniform half _Max_Distance;
        uniform half _Accuracy;
        uniform half _SphereSmooth;
    
        half4 _Bounds;
        half _Smooth;
        half _Height;
        half _WaveSmoothing;
        half _Max;
        half _MaxMinus;

        
        float2 _WaveOrigin;		// value used as the origin of the waves. 
        float3 _Origin;		// value used as the origin of the waves. 
        float2 _WaveOrigin2;		// value used as the origin of the waves. 
        float meanFrequency;
        float baseSpeed;
        float averageAmplitude;
        float numberOfWaves;


        float sdBox(float3 p, float3 dimensions) {
            float3 d = abs(p - _Origin.xyz) - dimensions;

            return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
        }

        float SmoothMin(float a, float b, float k) {
            float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
            return lerp(b, a, h) - k * h * (1.0 - h);
        }

    
      
        float CircleIntersect(half2 pointa, half2 center, float radius)
        {
            half2 oc = pointa - center;
            float c = dot(oc, oc) - radius * radius;
            float h = radius * radius - c;
            if (h < 0.0)
                return -1.0;
            return -sqrt(h);
        }
        //ripples from Fabrice's https://www.shadertoy.com/view/ldl3z2
        float tri(float amp, float fre, float spe, float dec, float3 pos)
        {
            float hForce = 0;
            float speed = 0;
            float height = 0;
            for (int i = 0; i < 2; i++)
            {
                hForce += 0.07 * _SphereSmooth;
            }
            speed += hForce;

            _Max += speed;
            speed *= 0.8f;

           
            float2 dis = pos.xz - (_Origin.xz + _WaveOrigin);
            float distance = length(dis) + _MaxMinus;//sqrt(dot(dis, dis));
            float2 dis2 = pos.xz - (_Origin.xz + _WaveOrigin2);
            float distance2 = length(dis2);//sqrt(dot(dis2, dis2));

            distance = min(distance2, distance);
                     
            return (amp * speed) * sin(fre * distance - _Time.y * spe) / (dec + distance * distance);

        }
       

        float Wave(half3 p) {
           
            float d;           
            float rip = tri(averageAmplitude, meanFrequency, baseSpeed, numberOfWaves, p);           
            
            d = p.y - max(-2., rip)  * _WaveSmoothing + _Height;
            d = -SmoothMin(-d, -sdBox(p, _Bounds.xyz - _Smooth) + _Smooth * 2., 0);
            
            return d;
        }
        half GetDist(half3 p) {

            half d = Wave(p);

            return half(d);
        }
    
        half3 Get_Normal(half3 pos) {
            half eps = 0.002;
            const half3 v1 = half3(1.0, -1.0, -1.0);
            const half3 v2 = half3(-1.0, -1.0, 1.0);
            const half3 v3 = half3(-1.0, 1.0, -1.0);
            const half3 v4 = half3(1.0, 1.0, 1.0);

            return normalize(v1 * GetDist(pos + v1 * eps) +
                v2 * GetDist(pos + v2 * eps) +
                v3 * GetDist(pos + v3 * eps) +
                v4 * GetDist(pos + v4 * eps));
        }

        half3 brdf(half3 ro, half3 pos, half3 normal, half3 lightDir, inout half3 col) {
            half percepinalrough = 1.0 - _Smoothness;
            half roughness = percepinalrough * percepinalrough;
            float3 halfDir = SafeNormalize(lightDir + pos);
            float nh = saturate(dot(normal, halfDir));
            float lh = saturate(dot(lightDir, halfDir));
            float d = nh * nh * (roughness * roughness - 1.0) + 1.00001;
            float normalizationTerm = roughness * 4.0 + 2.0;
            float specularTerm = roughness * roughness;
            specularTerm /= (d * d) * max(0.1, lh * lh) * normalizationTerm;
            col += specularTerm * _SpecPower;

            return col;
        }

        half _ShadowSoft(half3 ro, half3 rd, half mint, half maxt, half k) {
            half result = 1.0;
            for (half t = mint; t < maxt;) {

                half h = GetDist(ro + rd * t);
                if (h < 0.001) {
                    return 0.0;
                }
                result = min(result, k * h / t);
                t += h;
            }
            return result;
        }

        half3 _Shading(half3 p, half3 n, half3 rd) {
            Light lights = GetMainLight();
            half3 result;
            half3 color = _FirstColor.rgb;


            half ligh = saturate(saturate(dot(n, -rd)));
            half3 light = (_MainLightColor.rgb * ligh);

            color *= light;

            color *= 1.0 - _SpecPower;
            half shadow = _ShadowSoft(p, lights.direction, _ShadowMin, _ShadowMax, _ShadowPenumbra) * 0.5 + 0.5;
            shadow = max(0.0, pow(shadow, _ShadowIntensity));

            half3 test = brdf(rd, -rd, n, lights.direction, color);
            result = test * shadow;
            float relNorm = dot(n, rd);

            float sec = pow(relNorm, _EmmisionSize);
            float sec2 = pow(relNorm, _SpecColorSize);

            half3 absorbCol = lerp(_EmissionColor.rgb, result, sec);


            //absorbCol = lerp(absorbCol, _SpecColor.rgb, sec2);

            return (absorbCol);

        }

        half4 getSky(half3 rd)
        {
            if (rd.y > 0.25) return _SpecColor; 
            if (rd.y > _Smoothness) return _BaseColor;
            if (rd.y < 0.1) return _FirstColor; 

            if (rd.z > 0.9 && rd.x > 0.3) {
                if (rd.y > 0.2) return 2. * _BaseColor;
                return 1.5 * _BaseColor;
            }
            else return _EmissionColor; 
        }

        half3 shade(half3 normal, half3 pos, half3 rd)
        {
            float ReflectionFresnel = _Reflections;
            float fresnel = ReflectionFresnel * pow(1.0 - clamp(dot(-rd, normal), 0.0, 1.0), _Roughness) + (1.0 - ReflectionFresnel);
            half3 refVec = reflect(rd, normal);
            half4 reflection = getSky(refVec);

            float deep = _SpecColorSize + _SpecPower * pos.y;

            half3 col = fresnel * reflection;
            col += deep * _SpecPowerPreClamp * _SecondColor;

            return clamp(col, 0.0, 1.0);
        }

        half2 RayMarch(half3 rayOrigin, half3 rayDir, half depth, inout bool check) {
            float latest = _Accuracy * 2.0;
            float dist = +0.0;
            float type = -1.0;
            half2  res = half2(-1.0, -1.0);
            half3 pointOnSurface = 0;
          
            check = false;
            for (int i = 0; i < _Max_Steps; i++) {

                pointOnSurface = rayOrigin + rayDir * dist;
                if (dist > _Max_Distance ) { check = false; break; }
               
                half result = GetDist(pointOnSurface);
                latest = result;               
                dist += latest;
                
                if (result <= _Accuracy) {
                    res = half2(dist, 0);
                    check = true;
                    break;
                }
            }
                      

            return res;
        }
        v2f vert(appdata v)
        {
            v2f o = (v2f)0;
            VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
            o.uv = TRANSFORM_TEX(v.uv, _MainTex);
            o.ro = TransformWorldToObject(GetCameraPositionWS());
            float2 uvs = o.uv * 2 - 1;
            
            o.roWS = GetCameraPositionWS();
            o.hitPos = TransformWorldToObject(v.vertex.xyz);

            o.vertex = TransformObjectToHClip(v.vertex);
            o.screenPos = ComputeScreenPos(v.vertex);

            o.positionWS = TransformObjectToWorld(v.vertex.xyz);
            o.viewVectorWS = GetWorldSpaceViewDir(GetCameraPositionWS());
            float3 uvv = ComputeScreenPos(o.vertex);
            float3 viewVectors = mul(unity_CameraInvProjection, float4(v.uv * 2 - 1, 0, 0));
            o.viewVector = mul(unity_CameraToWorld, float4(viewVectors, 0));

            return o;
        }
        half4 frag(v2f i) : SV_Target
        {

            // sample the texture
            half2 uv = i.uv - 0.5;
            half4 color = _BaseColor.rgba;//tex2D(_MainTex, uv).rgb;
           
            half3 ro = (i.roWS);
            half3 rd = normalize(i.positionWS - ro);
        
            float viewDir = length(i.viewVector);
            float nonLinear = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.uv);
            float sceneEyeDepthtest = LinearEyeDepth(nonLinear, _ZBufferParams) * viewDir;

            bool check;
            half2 hit = RayMarch(ro, rd, sceneEyeDepthtest, check);

            if (check) {

                half3 pos = ro + rd * hit.x;
               
                half3 nor = Get_Normal(pos);
                half3 _shade = shade(nor, pos, rd);
                return  half4(_shade,1);
            }
            //else { discard; }

            clip(-1);
            return half4(0,0,0,1);

        }
            ENDHLSL

            SubShader {
            // UniversalPipeline needed to have this render in URP
            Tags{ "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" }

                // Forward Lit Pass
                Pass
            {
                Name "ForwardLit"
                Tags { "LightMode" = "UniversalForward" }

                Zwrite On
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
