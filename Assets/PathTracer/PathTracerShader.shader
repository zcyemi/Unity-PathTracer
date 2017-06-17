// Upgrade NOTE: replaced '_CameraToWorld' with 'unity_CameraToWorld'

Shader "Unlit/PathTracerShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
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
			#pragma target 4.5
			#include "UnityCG.cginc"
			#include "PathTracer.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 worldDir: TEXCOORD1;
				float4 screenPos: TEXCOORD2;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4x4 _ProjInv;
			float _u_iterations;

			

			
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				
				float4 pos = 2.0*(v.vertex - 0.5);
				pos.zw = 1.0;

				o.worldDir = mul(_ProjInv, pos);
				
				return o;
			}

			float3 intersect(RAY r)
			{
				float3 c = 0;
				float3 oc = c - r.origin;
				float dotc = dot(oc, r.dir);
				float len = length(oc);
				float ds = len*len - dotc*dotc;

				return step(ds, 0.25);
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				RAY r;
				i.worldDir /= i.worldDir.z;
				r.dir = normalize(i.worldDir);
				r.origin = _WorldSpaceCameraPos;
				r.IOR = 1.0;

				_initray = r.dir;

				float3 finalColor = 0;
				pathTracer(r, 1, finalColor);// intersect(r);

				float3 texColor = tex2D(_MainTex, i.uv);

				float3 retColor = lerp(finalColor/ depth, texColor, _u_iterations / (1.0 + _u_iterations));

				return fixed4(retColor,1.0);
			}
			ENDCG
		}
	}
}
