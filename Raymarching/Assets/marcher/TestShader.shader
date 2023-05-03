Shader "Unlit/TestShader"
{
    Properties
    {
       
        [MainTexture]_MainTex("Texture", 2D) = "white" {}
        _BaseColor("Color", Color) = (0, 0, 0.5, 0.3)
        
        _SpecColorSize("_SpecColorSize", Float) = 1.0
        [HDR]_SpecColor("Specular", Color) = (0.2, 0.2, 0.2)
      
         _EmmisionSize("EmmisionSize", Float) = 1.0
        [HDR] _EmissionColor("Color", Color) = (0,0,0)
        _Size("_Size", Float) = 1.0
        _Blend("_Blend", Float) = 1.0
        numballs("Balls", Float) = 1.0
        _Reflections("_Reflections", Range(0.0, 1.0)) = .5
       
       
        _Metallic("Metallic", Range(0.0, 1.0)) = 0.0

        _Roughness("_Roughness", Range(0.0, 1.0)) = 0.5
        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5
        _SpecPower("_SpecPower", Float) = 1.0
        _SpecPowerPreClamp("_SpecPowerPreClamp", Float) = 50.0

        _Max_Distance("_Max_Distance", Float) = 0.1
        _Max_steps("_Max_steps", Float) = 0.1
        _DinstanceAccuracy("_DinstanceAccuracy", Float) = 0.1

        _ShadowMin("_ShadowMin Distance", Float) = 0.1
        _ShadowMax("_ShadowMax_Distance", Float) = 100.0
        _ShadowIntensity("_ShadowIntensity", Float) = 5.0
        _ShadowPenumbra("_ShadowPenumbra", Float) = 5.0
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
    };

    struct v2f
    {
        float2 uv : TEXCOORD0;        
        float4 vertex : SV_POSITION;
        float3 rayOrigin : TEXCOORD1;
        float3 rayDirection : TEXCOORD2;
        float3 viewVector : TEXCOORD3;
        float4 projParams : TEXCOORD4;

    };

    TEXTURE2D(_MainTex);
    SAMPLER(sampler_MainTex);
   
    half4 _MainTex_ST;

    half4x4 _CameraInverseProjection;
    half4x4 _CameraWorld;
    half3 _CameraToWorldPosition;

    half _Max_Distance;
    half _Max_steps;
    half _DinstanceAccuracy;

    half _Size;
    half _Blend;
    half _Reflections;
    half _SpecColorSize;
    half _EmmisionSize;
    
    half3 _positions[60];
   
    half numballs;
    half3 _Position;
    half4 _BaseColor;
    half4 _SpecColor;
    half4 _EmissionColor;
    half4 _LightColor;

    half _Smoothness;
    half _Roughness;
    half _Metallic;
    half _SpecPower;
    half _SpecPowerPreClamp;

    half _ShadowMin;
    half _ShadowMax;
    half _ShadowIntensity;
    half _ShadowPenumbra;

    // polynomial smooth min (k = 0.1);
    // from https://www.iquilezles.org/www/articles/smin/smin.htm
    float unionSDF(float distA, float distB, float k) {
        float h = max(k - abs(distA - distB), 0.0) / k;
        return min(distA, distB) - h * h * k * (1.0 / 4.0);
    }
    //from https://www.iquilezles.org/www/articles/smin/smin.htm
    float sdSphere(float3 eye) {
        float m = 0.0;
        float p = 0.0;
        float dmin = 1e6;

        float h = 1.0;

        for (int i = 0; i < numballs; i++)
        {
            float db = length(_positions[i] - eye);
          
            if (db < _Size) {
                float x = db / _Size;
                p += 1.0 - x * x * x * (x * (x * 6.0 - 15.0) + 10.0);
                m += 1.0;
                h = max(h, .5 * _Size);
            }
            else {
                        
      
                dmin = min(dmin, db - _Size);
            }

           
        }
        half d = dmin + .1;

        if (m > 0.5) {
            float th = .1;
            d = h * (th - p);
        }

        return d;
    }
   
    half Sphere(half3 eye, half s) {
        float db = 0;
        half dx = 0;
        half dy = 0;
        half dz = 0;
        half r_squared = 0;
        for (int i = 0; i < numballs; i++)
        {
            dx = (eye.x - _positions[i].x);
            dy = (eye.y - _positions[i].y);
            dz = (eye.z - _positions[i].z);
            r_squared = (dx * dx + dy * dy + dz * dz);
           
          
        }
        if (r_squared < 0.5f)     // same as: if (sqrtf(r_squared) < 0.707f)
        {
            db += (0.25 - r_squared + r_squared * r_squared);
        }
        return db;
    }
    
    float GetDist(float3 eye) {
                
        return length(_positions[0] - eye) - _Size;
              
       
    }

    half3 Get_Norm(half3 p)
    {
        half2 e = half2(0.001, 0);
        half3 n = half3(
            sdSphere(p + e.xyy) - sdSphere(p - e.xyy),
            sdSphere(p + e.yxy) - sdSphere(p - e.yxy),
            sdSphere(p + e.yyx) - sdSphere(p - e.yyx));
        return normalize(n);
    }
    //https://catlikecoding.com/unity/tutorials/scriptable-render-pipeline/lights/ 
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
    half3 _Shading(half3 p, half3 n, half3 ro) {
        Light lights = GetMainLight();
        half3 result;
        half3 color = _BaseColor.rgb;
      

        half ligh = saturate(saturate(dot(n, p)));
        half3 light = (_MainLightColor.rgb * ligh);

        color *= light;

        //half specular = lerp(_SpecPower, color, _Metallic);
        //half reflectivity = lerp(_SpecPower, 1.0, _Metallic);
        //half fresStrenght = saturate(_Smoothness + reflectivity);

        color *= 1.0 - _SpecPower;
        half shadow = _ShadowSoft(p, lights.direction, _ShadowMin, _ShadowMax, _ShadowPenumbra) * 0.5 + 0.5;
        shadow = max(0.0, pow(shadow, _ShadowIntensity));

        half3 test = brdf(ro, -ro, n, lights.direction, color);
        result = test * shadow;
        float relNorm = dot(-ro, n);
                   
        float sec = pow(relNorm, _EmmisionSize);
        float sec2 = pow(relNorm, _SpecColorSize);

        half3 absorbCol = lerp(_EmissionColor.rgb, result, sec);
        
       
        absorbCol = lerp(absorbCol, _SpecColor.rgb, sec2);
       
        return (absorbCol);

    }

    struct Ray {
        float3 origin;
        float3 direction;
    };
    //https://github.com/SebLague
    Ray CreateRay(float3 origin, float3 direction) {
        Ray ray;
        ray.origin = origin;
        ray.direction = direction;
        return ray;
    }

    Ray CreateCameraRay(float2 uv) {
        float3 origin = mul(_CameraWorld, float4(0, 0, 0, 1)).xyz;
        float3 direction = mul(_CameraInverseProjection, float4(uv, 0, 1)).xyz;
        //direction /= abs(direction.z);
        direction = mul(_CameraWorld, float4(direction, 0)).xyz;
        //direction = normalize(direction);
        return CreateRay(origin, direction);
    }

    float SphereDistance(float3 ro, float3 rd, float3 center, float radius) {

        float3 oc = ro - center;
        float b = dot(oc, rd);
        float c = dot(oc, oc) - radius * radius;
        float h = b * b - c;
        if (h < 0.0) return -1.0;
        return -b - sqrt(h);
    }

    half when_Greater(half x, half y)
    {
        return max(sign(x - y), 0.0);
    }
    half when_negative(half x, half y)
    {
        return max(sign(y - x), 0.0);
    }
    half andOp(half x, half y)
    {
        return x * y;
    }
    half4 raymarch(float3 ro, float3 rd, float depth) {

        half4 ret = half4(0, 0, 0, 0);
        //float rayDst = 0; // current distance traveled along ray
        //float3 rOrigin = ro;

        float t = 0.0;

        float h = _DinstanceAccuracy * 2.0;
        float m = 1.0;
        for (uint i = 0; i < _Max_steps; i++)
        {
            if (h < _DinstanceAccuracy || t > _Max_Distance) break;
            t += h;
            h = sdSphere(ro + rd * t);
          
            /*float condition = when_Greater(h, 0.0);
            float condition2 = when_negative(h, t);*/

            /* t = lerp(t, h, condition * condition2);
             idx = lerp(idx, float(i), condition * condition2);
             obj = lerp(obj, sph, condition * condition2);*/

            
        }
        half3 position = ro + t * rd;
        if (t > _Max_Distance) m = -1.0;
        
        if (m > -.5 && depth > length(position - ro)) {
            half3 normal = Get_Norm(position);
            half3 shade = _Shading(position, normal, rd);
            ret = half4(shade, 1);
          
        }
        //half3 position = ro + t * rd;
        
       
       /* half3 position = ro + t * rd;
        half3 normal = normalize(position - obj);
        half3 shade = _Shading(position, normal, rd);*/
        return ret; //= lerp(half4(0, 0, 0, 0), half4(shade,1), when_Greater(idx, -0.5));
        //for (int i = 0; i < _Max_steps; i++)     
        //{
        //    float dst = GetDist(rOrigin);
        //    half3 pointOnSurface = rOrigin + rd * dst;
        //   
        //    if (rayDst > _Max_Distance || depth < length(pointOnSurface - ro)) {
        //        break;
        //    }
        //    if (dst <= _DinstanceAccuracy) {
        //       
        //        half3 norm = Get_Norm(pointOnSurface);               
        //        half3 tes = _Shading(pointOnSurface, norm, rd, dst);
        //        ret = float4(tes, _BaseColor.a);
        //        return ret;
        //        break;
        //    }
        //   
        //    rOrigin += rd * dst;
        //    rayDst += dst;

        //}        
        //return ret;
    }

    v2f vert(appdata v)
    {
        v2f o;
        o.vertex = TransformObjectToHClip(v.vertex);
              
        o.uv = TRANSFORM_TEX(v.uv, _MainTex);
        float2 uv = o.uv * 2 - 1;

        Ray ray = CreateCameraRay(uv);
        o.rayDirection = ray.direction;
        o.rayOrigin = ray.origin;
        float3 viewVector = mul(unity_CameraInvProjection, float4(o.uv * 2 - 1, 0, -1));
        o.viewVector = mul(unity_CameraToWorld, float4(viewVector, 0));
        o.projParams = ComputeScreenPos(o.vertex);
       
        return o;
    }

    half4 frag(v2f i) : SV_Target
    {       
        
        half3 rDirection = normalize(i.rayDirection);
        half3 rOrigin = i.rayOrigin;       
        
        float viewDir = length(i.rayDirection);
       
        float nonLinear = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.uv).r;
        float sceneEyeDepthtest = LinearEyeDepth(nonLinear, _ZBufferParams) * viewDir;               
       
        half4 add = raymarch(rOrigin, rDirection, sceneEyeDepthtest);
        // sample the texture
        half3 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv).rgb;       
       

        return half4(col * (1.0 - add.w) + add.xyz * add.w, 1.0);
        
    }

        ENDHLSL



        SubShader
    {
        // UniversalPipeline needed to have this render in URP
        Tags{ "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" }
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
            #pragma target 4.5

            // Lighting and shadow keywords
            #pragma shader_feature_local_fragment _SURFACE_TYPE_TRANSPARENT
            #pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON
            #pragma shader_feature_local_fragment _EMISSION
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

