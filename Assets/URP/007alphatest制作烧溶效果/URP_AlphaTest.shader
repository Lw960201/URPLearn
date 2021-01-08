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
                clip(step(_Cutoff,tex.r)-0.01);//使用step函数是为了更好得配合下面代码的lerp函数，只是为了凑个lerp的第三个参数，让tex.r可以作为控制参数
                //再次使用了step函数，但是将step函数的两个变量调换位置，这样就会得到与上面函数的值相反的区间，
                //注意我的_Cutoff+0.1是为了让它稍微偏移一点点并非100%与上面clip相反，它两是有一丢丢的相交部分，这就是火焰的边缘烧灼的部分了，在来个lerp，即可得到我们想要的结果。
                tex = lerp(tex,_BurnColor,step(tex.r,saturate(_Cutoff+0.1)));
                return tex;
            }
            ENDHLSL
        }
    }
}