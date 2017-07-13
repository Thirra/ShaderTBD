Shader "Custom/ObjectShader"
{
	Properties
	{
		_MainTex("Texture (R, G=X,Y Distortion; B=Mask; A=Unused)", 2D) = "white" {}
		_Tint("Tint (RGB)", Color) = (0.5,0.5,0.5,1)
		_IntensityAndScrolling("Intensity (XY); Scrolling (ZW)", Vector) = (0.1, 0.1, 1, 1)
		_DistanceFade("Distance Fade (X=Near, Y=Far, ZW=Unused)", Float) = (20, 50, 0, 0)
		[Toggle(MASK)] _MASK("Texture Blue channel is Mask", Float) = 0
		[Toggle(MIRROR_EDGE)] _MIRROR_EDGE("Mirror screen borders", Float) = 0
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode("Culling", Float) = 0

		[Toggle(DEBUGUV)] _DEBUGUV("Debug Texture Coordinates", Float) = 0
		[Toggle(DEBUGDISTANCEFADE)] _DEBUGDISTANCEFADE("Debug Distance Fade", Float) = 0
	}
		SubShader
		{
			Tags{ "Queue" = "Transparent" "IgnoreProjector" = "True" }
			Blend One Zero
			Lighting Off
			Fog{ Mode Off }
			ZWrite Off
			LOD 200
			Cull[_CullMode]

			GrabPass {"_GrabTexture"}

			Pass
			{
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma shader_feature MASK
				#pragma shader_feature MIRROR_EDGE
				#pragma shader_feature DEBUGUV
				#pragma shader_feature DEBUGDISTANCEFADE

				#define ENABLE_TINT 1
				#include "UnityCG.cginc"

				sampler2D _MainTex;
				float4 _MainTex_ST;
				sampler2D _GrabTexture;
				float4 _IntensityAndScrolling;

				//x=near distance at which distortions have full intensity
				//y=far ditance at which distortions have zero intensity
				half2 _DistanceFade;
				half3 _Tint;


				inline float2 Repeat(float2 t, float2 length)
				{
					return t - floor(t / length) * length;
				}

				inline float2 PingPong(float2 t, float2 length)
				{
					t = Repeat(t, length * 2);
					return length - abs(t - length);
				}

				struct appdata
				{
					float4 vertex : POSITION;
					//Used to be uv
					half2 texcoord : TEXCOORD0;
					fixed4 color : COLOR;
				};

				struct v2f
				{
					float4 vertex : SV_POSITION;
					half4 texcoord : TEXCOORD0; //xy = distort uv, zw = mask uv
					half4 screenuv : TEXCOORD1; //yx = screenuv, z = distance dependant intensity, w = depth
					fixed4 color : COLOR;
				};

				v2f vert(appdata v)
				{
					v2f o = (v2f)0;
					o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
					o.color = v.color;

					//Texcoord.xy stores the distortion texture coordinations
					o.texcoord.xy = TRANSFORM_TEX(v.texcoord, _MainTex); //Apply texture tiling and offset
					o.texcoord.xy += _Time.gg * _IntensityAndScrolling.zw; //Apply texture scrolling

					//Texcoord.zw stores the distortion mask texture coordinates.
					//We don't want to scroll the mask, so we just use the original texture coords
					o.texcoord.zw = v.texcoord;

					half4 screenpos = ComputeGrabScreenPos(o.vertex);
					o.screenuv.xy = screenpos.xy / screenpos.w;

					//Calculate distance depended intensity
					//Blend intensity linearily between near to far params
					half depth = length(mul(UNITY_MATRIX_MVP, v.vertex));
					o.screenuv.z = saturate((_DistanceFade.y - depth) / (_DistanceFade.y - _DistanceFade.x));
					o.screenuv.w = depth;

					return o;
				}

				fixed4 frag(v2f i) : COLOR
				{
					half2 distort = tex2D(_MainTex, i.texcoord.xy).xy;

					// distort*2-1 transforms range from 0..1 to -1..1.
					// negative values move to the left, positive to the right.
					half2 offset = (distort.xy * 2 - 1) * _IntensityAndScrolling.xy * i.screenuv.z * i.color.a;

#if ENABLE_TINT
					half3 tint = _Tint;
#endif

#if MASK
					// _MainTex stores in the blue channel the mask.
					// The mask intensity represents how strong the distortion should be for this pixel.
					// black=no distortion, white=full distortion
					half  mask = tex2D(_MainTex, i.texcoord.zw).b;
					offset *= mask;

#if ENABLE_TINT
					// Push tint towards white where distortions are not applied.
					// This makes the tint fade out using the mask.
					tint = lerp(tint, half3(0.5,0.5,0.5), 1 - mask);
#endif
#endif							

#if ENABLE_CLIP				
					// Clip pixel if offset is really small. This makes masked particle
					// distortions blend together slightly better.
					clip(dot(offset,1) - 0.0001);
#endif					

					// get screen space position of current pixel
					half2 uv = i.screenuv.xy + offset;

#if MIRROR_EDGE
					// Mirror uv's when it goes out of the screen.
					// This avoids streched seams at screen borders by introducing
					// these kind of mirroring artifacts. It looks less disturbing than the border seams though.
					uv = PingPong(uv, 1);
#endif

					half4 color = tex2D(_GrabTexture, uv);
#if ENABLE_TINT
					color.rgb *= tint * 2;
#endif
					UNITY_OPAQUE_ALPHA(color.a);

#if DEBUGUV
					color.rg = uv;
					color.b = 0;
#endif

#if DEBUGDISTANCEFADE
					color.rgb = lerp(half3(1,0,0), half3(0,1,0), i.screenuv.z);
#endif

					//color.rgb = float3(fade,fade,fade)*15;
					return color;
			}
			ENDCG
		}
	}
}

