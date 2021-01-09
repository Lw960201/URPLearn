Shader "URP/URP_MainLightShadow"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" {}
        _BaseColor("Base Color", Color) = (1,1,1,1)
        _Gloss("Gloss",Range(10,300)) = 20
        _SpecularColor("Specular Color",Color) = (1,1,1,1)
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalRenderPipeline"
            "RenderType"="Opaque"
        }


        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        real4 _BaseColor;
        float _Gloss;
        half4 _SpecularColor;
        CBUFFER_END

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

        struct a2v
        {
            float4 positionOS : POSITION;
            float2 texcoord:TEXCOORD;
            float4 normalOS:NORMAL;
        };

        struct v2f
        {
            float4 positionCS : SV_POSITION;
            float2 texcoord:TEXCOORD;
            float3 WS_N:NORMAL;
            float3 WS_P:TEXCOORD1;
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
            #pragma multi_compile __ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile __ _MAIN_LIGHT_SHADOWS_CASCADE
            //柔化阴影，得到软阴影
            #pragma multi_compile __ _SHADOWS_SOFT

            v2f vert(a2v i)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.texcoord = TRANSFORM_TEX(i.texcoord,_MainTex);
                o.WS_N = normalize(TransformObjectToWorldNormal(i.normalOS.xyz));
                o.WS_P = TransformObjectToWorld(i.positionOS.xyz);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                half4 tex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.texcoord)*_BaseColor;
                Light myLight = GetMainLight(TransformWorldToShadowCoord(i.WS_P));
                float WS_View = normalize(_WorldSpaceCameraPos-i.WS_P);
                float3 WS_Light = normalize(myLight.direction);
                float3 WS_H = normalize(WS_View + WS_Light);//半程向量

                float3 WS_Normal = normalize(i.WS_N);
                tex *= (dot(WS_Light,WS_Normal)*0.5+0.5)*myLight.shadowAttenuation*real4(myLight.color,1);
                float4 Specular = pow(max(dot(WS_Normal,WS_H),0),_Gloss)* _SpecularColor * myLight.shadowAttenuation;
                return tex + Specular;
            }
            ENDHLSL
        }

        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
}