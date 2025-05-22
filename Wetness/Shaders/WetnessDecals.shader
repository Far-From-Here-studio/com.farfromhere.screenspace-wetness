Shader "Custom/SimpleDecal"
{
    Properties
    {
        _DecalTexture("Decal Texture", 2D) = "white" {}
        _DecalColor("Decal Color", Color) = (1,1,1,1)
        _DecalScale("Decal Scale", Vector) = (1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Overlay" }
        Pass
        {
            Name "DecalPass"
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Back

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _DecalTexture;
            float4 _DecalColor;
            float3 _DecalScale;

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 position : SV_POSITION;
                float3 worldPos : TEXCOORD0;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.position = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                // Transform the world position to local decal space
                float3 localPos = mul(unity_WorldToObject, float4(i.worldPos, 1.0)).xyz;

                // Normalize to decal UV space
                float3 decalUV = localPos / _DecalScale;

                // Check if the UVs are within bounds (-0.5 to 0.5 in all axes)
                if (any(abs(decalUV) > 0.5))
                {
                    // Discard pixels outside the decal volume
                    discard;
                }

                // Sample the decal texture
                float2 uv = decalUV.xy + 0.5; // Convert from [-0.5, 0.5] to [0, 1]
                float4 decalTexColor = tex2D(_DecalTexture, uv);

                // Multiply the texture color with the decal color
                float4 outputColor = decalTexColor * _DecalColor;

                return outputColor;
            }
            ENDHLSL
        }
    }
}
