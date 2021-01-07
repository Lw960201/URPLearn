Shader "URP/URP_RampTexShader"
{
    Properties
    {
        _MainTex ("Ramp", 2D) = "white" {}
        _BaseColor("Base Color", Color) = (1,1,1,1)
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalRenderPipeline"
        }


        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        real4 _BaseColor;
        CBUFFER_END

        //TEXTURE2D(_MainTex);
        //SAMPLER(sampler_MainTex);
        sampler2D _MainTex;

        struct a2v
        {
            float4 positionOS : POSITION;
            float3 normalOS: NORMAL;
        };

        struct v2f
        {
            float4 positionCS : SV_POSITION;
            float3 normalWS:NORMAL;
        };
        
        ENDHLSL

        pass
        {
            Tags
            {
                "LightMode"="UniversalForward"
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            v2f vert(a2v i)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.normalWS = normalize(TransformObjectToWorldNormal(i.normalOS));
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                real3 lightDir = normalize(GetMainLight().direction);
                float dott = saturate(dot(i.normalWS,lightDir)*0.5+0.5);
                half4 tex = tex2D(_MainTex,float2(dott,0.5))*_BaseColor;

                return tex;
            }
            ENDHLSL
        }
    }
}