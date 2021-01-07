Shader "URP/URP_NormalTexShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BaseColor("Base Color", Color) = (1,1,1,1)
        [Normal]_NormalTex("Normal", 2D) = "bump"{}
        _NormalScale("Normal Scale", Range(0,1)) = 1
        _SpecularRange("Specular Range", Range(1,200))=50
        _SpecularColor("Specular Color", Color) =(1,1,1,1)
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
        float4 _NormalTex_ST;
        real4 _BaseColor;
        real _NormalScale;
        float _SpecularRange;
        real4 _SpecularColor;
        CBUFFER_END

        TEXTURE2D(_MainTex);
        TEXTURE2D(_NormalTex);
        SAMPLER(sampler_MainTex);
        SAMPLER(sampler_NormalTex);

        struct a2v
        {
            float3 positionOS : POSITION;
            float2 texcoord : TEXCOORD0;
            float3 normalOS: NORMAL;
            float4 tangentOS:TANGENT;
        };

        struct v2f
        {
            float4 positionCS : SV_POSITION;
            float4 texcoord : TEXCOORD0;
            float4 tangentWS:TANGENT;
            float4 normalWS:NORMAL;
            float4 BtangentWS:TEXCOORD1;
        };
        
        ENDHLSL

        pass
        {
            NAME "MainPass"
            
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
                o.texcoord.xy = TRANSFORM_TEX(i.texcoord, _MainTex);
                o.texcoord.zw = TRANSFORM_TEX(i.texcoord, _NormalTex);
            
                o.positionCS = TransformObjectToHClip(i.positionOS);
                //TBN
                o.normalWS.xyz = normalize((i.normalOS.xyz));//N
                o.tangentWS.xyz = normalize(TransformObjectToWorld((i.tangentOS)));//T
                o.BtangentWS.xyz = cross(o.normalWS.xyz,o.tangentWS.xyz) * i.tangentOS.w * unity_WorldTransformParams.w;//B//unity_WorldTransformParams.w负奇数缩放影响因子

                float3 positionWS = TransformObjectToWorld(i.positionOS);
                o.tangentWS.w = positionWS.x;
                o.BtangentWS.w = positionWS.y;
                o.normalWS.w = positionWS.z;
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                float3 WSpos = float3(i.tangentWS.w,i.BtangentWS.w,i.normalWS.w);
                float3x3 T2W = {i.tangentWS.xyz,i.BtangentWS.xyz,i.normalWS.xyz};//TBN矩阵
                real4 nortex = SAMPLE_TEXTURE2D(_NormalTex,sampler_NormalTex,i.texcoord.zw);
                float3 normalTS = UnpackNormalScale(nortex,_NormalScale);
                normalTS.z = pow(1-saturate(dot(normalTS.xy,normalTS.xy)),0.5);//规范化法线
                float3 norWS = mul(normalTS,T2W);//注意这里是右乘T2W的，等同于左乘T2W的逆
                //
                Light mylight = GetMainLight();
                float halfLambot = dot(norWS,normalize(mylight.direction))*0.5 +0.5;//计算兰伯特
                real4 diff = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord.xy) * halfLambot * _BaseColor * real4(mylight.color,1);
                
                float spe = saturate(dot(normalize(mylight.direction + normalize(_WorldSpaceCameraPos-WSpos)), norWS));
                spe = pow(spe, _SpecularRange) * _SpecularColor;

                return spe + diff;
            }
            ENDHLSL
        }
    }
}