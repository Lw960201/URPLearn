Shader "URP/URP_MultiLight"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" {}
        _BaseColor("Base Color", Color) = (1,1,1,1)
        [KeywordEnum(ON,OFF)]_ADD_LIGHT("Add Light",float) = 1
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
            float3 WS_V:TEXCOORD1;
            float3 WS_P:TEXCOORD2;
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
            #pragma shader_feature _ADD_LIGHT_ON _ADD_LIGHT_OFF

            v2f vert(a2v i)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.texcoord = TRANSFORM_TEX(i.texcoord,_MainTex);
                o.WS_N = normalize(TransformObjectToWorldNormal(i.normalOS.xyz));
                o.WS_V = normalize(_WorldSpaceCameraPos-TransformObjectToWorld(i.positionOS.xyz));
                o.WS_P = TransformObjectToWorld(i.positionOS.xyz);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                half4 tex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.texcoord)*_BaseColor;
                Light myLight = GetMainLight();
                float WS_View = i.WS_V;
                float3 WS_Light = normalize(myLight.direction);
                float3 WS_H = normalize(WS_View + WS_Light);//半程向量

                float3 WS_Normal = i.WS_N;
                float4 mainColor= (dot(WS_Light,WS_Normal)*0.5+0.5)*tex*float4(myLight.color,1);

                //计算额外光照
                real4 addColor = real4(0,0,0,1);
                #if _ADD_LIGHT_ON
                float3 WS_Pos = i.WS_P;
                int addLightsCount = GetAdditionalLightsCount(); //定义在lighting库函数的方法，返回一个额外灯光的数量
                for (int i = 0; i < addLightsCount;i++)
                {
                    Light addlight = GetAdditionalLight(i,WS_Pos);//定义在lighting库函数的方法，返回一个灯光类型的数据
                    float3 WS_addLightDir = normalize(addlight.direction);
                    addColor += (dot(WS_Normal,WS_addLightDir)*0.5+0.5)*real4(addlight.color,1)*tex*addlight.distanceAttenuation*addlight.shadowAttenuation;
                }
                #else
                addColor = real4(0,0,0,1);
                #endif
                return  mainColor + addColor;
            }
            ENDHLSL
        }
    }
}