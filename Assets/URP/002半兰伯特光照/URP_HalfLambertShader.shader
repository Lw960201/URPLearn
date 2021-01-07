Shader "URP/HalfLambert"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BaseColor("Base Color",Color) = (1,1,1,1)
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
            float3 normal:TEXCOORD1;
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
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = TransformObjectToWorldNormal(v.normal.xyz);
                return o;
            }

            half4 FRAG(v2f i) : SV_Target
            {
                half4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv) * _BaseColor;
                Light mylight = GetMainLight();
                real4 LightColor = real4(mylight.color, 1);
                float3 LightDir = normalize(mylight.direction);
                float LightAten = dot(LightDir, i.normal);
                //return tex * LightAten * LightColor; 
                return tex * LightAten * LightColor * 0.5 + 0.5; //半兰伯特光照模型
            }
            ENDHLSL
        }
    }
}