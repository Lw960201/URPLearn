Shader "URP/UnlitShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BaseColor("Base Color",Color) = (1,1,1,1)
    }

    SubShader
    {
        Tags { 
            "RenderType"="Opaque" 
            "RenderPipeline"="UniversalRenderPipeline"
        }


        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

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
        };

        ENDHLSL

        pass
        {
            HLSLPROGRAM

            #pragma vertex VERT
            #pragma fragment FRAG

            v2f VERT (a2v v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            half4 FRAG (v2f i) : SV_Target
            {
                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, i.uv)*_BaseColor;
                return col;
            }

            ENDHLSL

        }

        
    }
}
