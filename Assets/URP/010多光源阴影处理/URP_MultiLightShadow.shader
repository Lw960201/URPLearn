Shader "URP/URP_MultiLightShadow"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" {}
        _BaseColor("Base Color", Color) = (1,1,1,1)
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
            float3 WS_V:TEXCOORD2;
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
            #pragma multi_compile __ _ADDITIONAL_LIGHT_SHADOWS
            //柔化阴影，得到软阴影
            #pragma multi_compile __ _SHADOWS_SOFT

            v2f vert(a2v i)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.texcoord = TRANSFORM_TEX(i.texcoord,_MainTex);
                o.WS_N = normalize(TransformObjectToWorldNormal(i.normalOS.xyz));
                o.WS_P = TransformObjectToWorld(i.positionOS.xyz);
                o.WS_V = normalize(_WorldSpaceCameraPos-o.WS_P);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                half4 shadowTexcoord = TransformWorldToShadowCoord(i.WS_P);
                half4 tex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.texcoord)*_BaseColor;
                Light myLight = GetMainLight(shadowTexcoord);
                float3 WS_Light = normalize(myLight.direction);
                float3 WS_Normal = normalize(i.WS_N);
                float3 WS_View = i.WS_V;
                float3 WS_H = normalize(WS_View + WS_Light);
                float3 WS_Pos = i.WS_P;
                //计算主光源
                float4 maincolor = (dot(WS_Light,WS_Normal)*0.5+0.5)* tex * myLight.shadowAttenuation*real4(myLight.color,1);
                //计算额外光源
                real4 addcolor = real4(0,0,0,1);
                int addLightsCount = GetAdditionalLightsCount();
                for (int i = 0; i < addLightsCount ; i++)
                {
                    Light addlight = GetAdditionalLight(i,WS_Pos);
                    float3 WS_addLightDir = normalize(addlight.direction);
                    addcolor += (dot(WS_Normal,WS_addLightDir)*0.5+0.5) * real4(addlight.color,1) * tex * addlight.distanceAttenuation *addlight.shadowAttenuation;
                }
                return maincolor + addcolor;
            }
            ENDHLSL
        }

        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
}