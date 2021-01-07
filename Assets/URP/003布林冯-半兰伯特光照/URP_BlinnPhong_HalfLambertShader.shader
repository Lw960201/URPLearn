Shader "URP/URP_BlinnPhong_HalfLambertShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BaseColor("Base Color",Color) = (1,1,1,1)
        _SpecularRange("Specular Range",Range(10,300))=10
        _SpecularColor("Specular Color",Color) =(1,1,1,1)
    }

    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
            "RenderPipeline"="UniversalRenderPipeline"
        }


        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        half4 _BaseColor;
        float _SpecularRange;
        real4 _SpecularColor;
        CBUFFER_END

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

                struct a2v
        {
            float4 vertex : POSITION;
            float4 normal: NORMAL;
            float2 uv : TEXCOORD0;
        };

        struct v2f
        {
            float4 vertex : SV_POSITION;
            float2 uv : TEXCOORD0;
            float3 viewDir:TEXCOORD1;
            float3 normal:NORMAL;
        };
        
        ENDHLSL

        pass
        {
            Tags
            {
                "LightMode"="UniversalForward"
            }

            HLSLPROGRAM
            #pragma vertex VERT
            #pragma fragment FRAG

            v2f VERT(a2v v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.normal = TransformObjectToWorldNormal(v.normal.xyz);
                o.viewDir = normalize(_WorldSpaceCameraPos - TransformObjectToWorld(v.vertex.xyz));
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            half4 FRAG(v2f i) : SV_Target
            {
                Light mylight = GetMainLight();
                float3 LightDir = normalize(mylight.direction);
                float spe = saturate(dot(normalize(LightDir+i.viewDir),i.normal));
                real4 specolor = pow(spe,_SpecularRange)*_SpecularColor;
                half4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv) * _BaseColor;
                real4 LightColor = real4(mylight.color, 1);
                float LightAten = dot(LightDir, i.normal);
                tex *=LightColor * LightAten;
                tex = tex*0.5+0.5;

                return tex + specolor;
            }
            ENDHLSL
        }
    }
}