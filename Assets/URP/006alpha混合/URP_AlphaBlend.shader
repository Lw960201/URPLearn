Shader "URP/URP_AlphaBlend"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" {}
        _AlphaTex ("AlphaTex", 2D) = "white" {}
        _BaseColor("Base Color", Color) = (1,1,1,1)
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalRenderPipeline"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }


        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        real4 _BaseColor;
        float4 _AlphaTex_ST;
        CBUFFER_END

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_AlphaTex);
        SAMPLER(sampler_AlphaTex);

        struct a2v
        {
            float4 positionOS : POSITION;
            float4 normalOS: NORMAL;
            float2 texcoord:TEXCOORD;
        };

        struct v2f
        {
            float4 positionCS : SV_POSITION;
            float4 texcoord:TEXCOORD;
        };
        
        ENDHLSL

        pass
        {
            Tags
            {
                "LightMode"="UniversalForward"
            }
            
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            v2f vert(a2v i)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.texcoord.xy = TRANSFORM_TEX(i.texcoord,_MainTex);
                o.texcoord.zw = TRANSFORM_TEX(i.texcoord,_AlphaTex);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                half4 tex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.texcoord.xy)*_BaseColor;
                float alpha = SAMPLE_TEXTURE2D(_AlphaTex,sampler_AlphaTex,i.texcoord.zw).r;
                return real4(tex.xyz,alpha);
            }
            ENDHLSL
        }
    }
}