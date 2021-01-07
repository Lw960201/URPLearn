Shader "URP/URP_AlphaTest"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" {}
        _BaseColor("Base Color", Color) = (1,1,1,1)
        _Cutoff("Cutoff",float) = 1
        [HDR]_BurnColor("Burn Color", Color) = (2.5,1,1,1)
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalRenderPipeline"
            "RenderType"="TransparentCutout"
            "Queue"="AlphaTest"
        }


        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        real4 _BaseColor;
        float4 _BurnColor;
        float _Cutoff;
        CBUFFER_END

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

        struct a2v
        {
            float4 positionOS : POSITION;
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
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                half4 tex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.texcoord.xy)*_BaseColor;
                clip(step(_Cutoff,tex.r)-0.01);
                tex = lerp(tex,_BurnColor,step(tex.r,saturate(_Cutoff+0.1)));
                return tex;
            }
            ENDHLSL
        }
    }
}