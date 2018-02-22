// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/Raymarcher"
{
	Properties
	{
		 [NoScaleOffset] _MainTex ("Texture", 2D) = "white" {}
		 //_arvo ("Säätö", color) = color(0, 0, 0, 1) {}
		 _globalTime ("Time", float) = 0.0
	}
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"  // tutorial sanoo, että turha riisutussa shaderissä

			float _globalTime;

			struct appdata
			{
				float4 vertex : POSITION; // vertex position
				float2 uv : TEXCOORD0;	  // texture coordinate
			};

			struct v2f  // vertex to fragment
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION; // clip space position (mikä?)
				float3 viewDirection : TEXCOORD1;
			};

			// vertex shader
			v2f vert (appdata v)
			{
				v2f output;
				// multiply with model*view*projection matrix
				output.vertex = UnityObjectToClipPos(v.vertex);
				output.uv = v.uv;
				output.viewDirection = WorldSpaceViewDir(v.vertex);

				return output;
			}

			// texture we will sample
			sampler2D _MainTex;


			float scaletester(float input) {
				if (input > 1) return 0;
				if (input < 0) return 1;
				return input * 0.5 + 0.25;
			}

			// square wave
			int sqw(float x) {
				return max(0, int(sin(x)+1));
			}

			float3x3 rotateXZ(float angle) {
				return float3x3(
					cos(angle), 0, sin(angle),
					0, 1, 0,
					-sin(angle), 0, cos(angle));
			}

			float3x3 rotateYZ(float angle) {
				return float3x3(
					1, 0, 0,
					0, cos(angle), sin(angle),
					0, -sin(angle), cos(angle));
			}

			// Box
			float box(float3 p, float3 dimensions) {
				return length(max(abs(p) - dimensions * 0.5, 0.0));
			}

			// Distance estimator
			float distanceEstimator(float3 position) {
				float3 p = position - float3(0, 3, 2);
				//p = mul(rotateYZ(_Time.y * 0.01), p);
				//p = mul(rotateXZ(_Time.y * 0.05), p);

				return min(box(p, float3(1.0, 0.2, 2.0)), box(position - float3(0, 0.15, 2), float3(4.0, 0.2, 4.0)));
			}



			// pixel shader - returns low precision "fixed4" type
			fixed4 frag (v2f input) : SV_Target
			{
				
				float3 eyePosition = _WorldSpaceCameraPos;
				float3 viewDirection = -normalize(input.viewDirection);
				float3 rayPosition;
				float stepNumber = 0;
				float travelDistance = 0.01;
				float distanceToSurface = 1.0;
				float touchDistance = 0.01;
				float maxSteps = 100; //1000
				float maxDistance = 200;
				float travelMultiplier = 0.75; //0.35

				while (travelDistance < maxDistance && distanceToSurface > touchDistance && stepNumber < maxSteps) {
					stepNumber += 1;
					rayPosition = eyePosition + travelDistance * viewDirection;
					distanceToSurface = distanceEstimator(rayPosition);
					travelDistance += travelMultiplier * distanceToSurface;
					touchDistance = 0.0003 * travelDistance;
				}

				bool didHitSurface = distanceToSurface <= touchDistance;

				float brightness = stepNumber/maxSteps;
				if (!didHitSurface) {
					brightness = 1 - brightness;
				}
				return float4(brightness, brightness, brightness, 1);
			}
			ENDCG
		}
	}
}
