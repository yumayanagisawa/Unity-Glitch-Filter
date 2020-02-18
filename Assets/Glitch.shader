// Glitch filter study based on this shader https://www.shadertoy.com/view/MtXBDs
Shader "Unlit/Glitch"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		iChannel0("Tex", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

			sampler2D iChannel0;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

			float random2d(float2 n) {
				return frac(sin(dot(n, float2(12.9898, 4.1414))) * 43758.5453);
			}

			float randomRange(in float2 seed, in float min, in float max) {
				return min + random2d(seed) * (max - min);
			}

			float insideRange(float v, float bottom, float top) {
				return step(bottom, v) - step(top, v);
			}

			// inputs
			static const float AMT = 0.2;
			static const float SPEED = 0.6;

            fixed4 frag (v2f i) : SV_Target
            {
				float time = floor(_Time.y * SPEED * 60.0);
				float2 uv = i.uv.xy;//fragCoord.xy / iResolution.xy;

				// copy orig
				float3 outCol = tex2D(iChannel0, uv).rgb;

				// randomly offset slices horizontally
				float maxOffset = AMT / 2.0;
				for (float i = 0; i < 10.0 * AMT; i++)
				{
					float sliceY = random2d(float2(time, 2345.0 + float(i)));
					float sliceH = random2d(float2(time, 9035.0 + float(i))) * 0.25;
					float hOffset = randomRange(float2(time, 9625.0 + float(i)), -maxOffset, maxOffset);

					float2 uvOff = uv;
					uvOff.x += hOffset;
					if (insideRange(uv.y, sliceY, frac(sliceY+sliceH)) == 1.0)
					{
						outCol = tex2D(iChannel0, uvOff).rgb;
					}
				}

				// do slight offset on one entire channel
				float maxColOffset = AMT / 6.0;
				float rnd = random2d(float2(time, 9545.0));
				float2 colOffset = float2(randomRange(float2(time, 9545.0), -maxColOffset, maxColOffset),
					randomRange(float2(time, 7205.0), -maxColOffset, maxColOffset));
				if (rnd < 0.33)
				{
					outCol.r = tex2D(iChannel0, uv + colOffset).r;
				}
				else if (rnd < 0.66)
				{
					outCol.g = tex2D(iChannel0, uv + colOffset).g;
				}
				else {
					outCol.b = tex2D(iChannel0, uv + colOffset).b;
				}

				return float4(outCol, 1.0);
            }
            ENDCG
        }
    }
}
