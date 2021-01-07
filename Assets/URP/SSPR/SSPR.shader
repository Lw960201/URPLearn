Shader "Unlit/SSPR"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BaseColor("BaseColor",Color)=(1,1,1,1)
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
            "Queue"="Overlay"
        }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct a2v
            {
                float4 positionOS:POSITION;
                float4 normalOS:NORMAL;
                float2 texcoord:TEXCOORD;
            };

            struct v2f
            {
                float4 positionCS:SV_POSITION;
                float2 texcoord:TEXCOORD;
                float4 screenPos:TEXCOORD1;
                float3 posWS:TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            half4 _BaseColor;
            sampler2D _ReflectColor;

            v2f vert(a2v v)
            {
                v2f o;
                o.positionCS = UnityObjectToClipPos(v.positionOS);
                o.screenPos = ComputeScreenPos(o.positionCS);
                UNITY_TRANSFER_FOG(o, o.positionCS);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                half2 screenUV = i.screenPos.xy / i.screenPos.w;
                float4 SSPRResult = tex2D(_ReflectColor, screenUV);
                SSPRResult.xyz *= SSPRResult.w;
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, SSPRResult);
                return SSPRResult;
            }
            ENDCG
        }
    }
}