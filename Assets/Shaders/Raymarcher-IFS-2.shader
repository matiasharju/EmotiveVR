// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/Raymarcher"
{
	Properties
	{
		 [NoScaleOffset] _MainTex ("Texture", 2D) = "white" {}
		 //_arvo ("Säätö", color) = color(0, 0, 0, 1) {}
		 _globalTime ("Time", float) = 0.0
		 _iterations ("Iteration Count", int) = 4
		 _baseSpeed ("Global Animation Speed", float) = 0.1

	}
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			float _globalTime; // ei käytössä. ei ehkä tarvettakaan.

			int foldCount;
			float _baseSpeed; 
			int _iterations;

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

			float box(float3 p, float3 dimensions) {
				return length(max(abs(p) - dimensions * 0.5, 0.0));
			}

			float sphereDE(float3 p, float radius) {
				return length(p) - radius;
			}

			float torusDE(float3 p, float2 t) {
				float2 q = float2(length(p.xz)-t.x, p.y);
				return length(q)-t.y;
			}
			float3 foldIterator(float3 p) {
				for (int i = 0; i < _iterations; i++) {
					//p = orientation * p; // orientation ei ole mukana
					float3 foldNormal; // = float3(1,0,0);

					p -= float3(0, 0.02, 0);
					if (i%3 == 2) {
						foldNormal = float3(cos(_Time.y * _baseSpeed * 0.5), 
									 		sin(_Time.y * _baseSpeed * 0.1),
									 		0);
			 		} else {
			 			foldNormal = float3(0,
									 		-sin(_Time.y * _baseSpeed * 0.1),
									 		cos(_Time.y * _baseSpeed * 0.1));
					}
					p -= 2.0 * min((sin(_Time * _baseSpeed) + 2.0) * 0.1, dot(p, foldNormal)) * foldNormal;
					p = mul(rotateXZ(sin(_Time * _baseSpeed)), p);
					//p = mul(rotateXZ(viewDirection.angle.y), p);

					if (dot(p, foldNormal) > 0) {
						foldCount += 1;
					}


				 } 
				return p;
			}

			// Distance estimator
			float distanceEstimator(float3 position) {

				foldCount = 0;
				float3 p = position - float3(1, 3, 2.5);

				p = foldIterator(p);

				float element1 = sphereDE(p, float(0.3));
				float element2 = box(position - float3(0.1, -0.25, 1.8), float3(4.0, 0.2, 4.0)); //Slab

				p = mul(rotateYZ(_Time.y * 0.01), p);
				p = mul(rotateXZ(_Time.y * 0.05), p);
				return min(element1, element2);
			}



			// pixel shader - returns low precision "fixed4" type
			fixed4 frag (v2f input) : SV_Target
			{

				// Raymarch parameters
				float maxSteps = 96;
				float maxDistance = 70;
				float travelMultiplier = 0.25;
				float touchDistanceMultiplier = 0.001;

				// Raymarch code
				float3 eyePosition = _WorldSpaceCameraPos;
				float3 viewDirection = -normalize(input.viewDirection);
				float stepNumber = 0;
				float travelDistance = 0;
				float3 rayPosition;
				float distanceToSurface;
				float touchDistance;

				while ((stepNumber == 0) || (travelDistance < maxDistance && distanceToSurface > touchDistance && stepNumber < maxSteps)) {
					stepNumber += 1;
					rayPosition = eyePosition + travelDistance * viewDirection;
					distanceToSurface = distanceEstimator(rayPosition);
					travelDistance += travelMultiplier * distanceToSurface;
					touchDistance = touchDistanceMultiplier * travelDistance;
				}

				bool didHitSurface = distanceToSurface <= touchDistance;

				//stepNumber = maxSteps - stepNumber;
				float brightness = stepNumber/maxSteps;
				if (!didHitSurface) {
					brightness = 1 - brightness;
					brightness = pow(brightness, 1.4);
					return float4(pow(brightness, 2), pow(brightness, 0.9), pow(brightness, 0.7), 1);
				}
				brightness = log(stepNumber) / log(maxSteps);
				brightness = pow(brightness, 4);
				return float4(brightness, brightness, brightness, 1);
			}
			ENDCG
		}
	}
}
