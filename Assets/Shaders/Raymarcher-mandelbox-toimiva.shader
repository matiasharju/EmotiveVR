// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/Raymarcher"
{
	Properties
	{
		 [NoScaleOffset] _MainTex ("Texture", 2D) = "white" {}
		 _iterations ("Iteration Count", int) = 4
		 _baseSpeed ("Global Animation Speed", float) = 0.1
         _globalTime ("Global Time", float) = 0.0

	}
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
            
			int foldCount;
			uniform int _iterations;
            uniform float _baseSpeed; 
            uniform float _globalTime;

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

            // Rotations
			float3x3 rotateXY(float angle) {
				return float3x3(
					cos(angle), sin(angle), 0,
					-sin(angle), cos(angle), 0,
					0, 0, 1);
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

            // Basic Primitives
			float boxDE(float3 p, float3 dimensions) {
				return length(max(abs(p) - dimensions * 0.5, 0.0));
			}

            // Mandelbox
			float mandelboxDE(float3 testPoint) {
				float scale = 2;
				float smallRadius = 0.5;
				float bigRadius = 1;

				float derivative = 1;
				float3 p = testPoint;
				float smallRadiusSquared = smallRadius * smallRadius;

				for (int i = 0; i < _iterations; i++) {

					// Box fold
					if (p.x > 1) p.x = 2 - p.x;
					else if (p.x < -1) p.x = -2 - p.x;
					if (p.y > 1) p.y = 2 - p.y;
					else if (p.y < -1) p.y = -2 - p.y;
					if (p.z > 1) p.z = 2 - p.z;
					else if (p.z < -1) p.z = -2 - p.z;

					// Special sphere fold
					float lengthSquared = dot(p, p);
					if (lengthSquared < 0.25) {
						derivative *= 4;
						p *= 4;
					} else if (lengthSquared < 1) {
						derivative /= lengthSquared;
						p /= lengthSquared;
					}

					// Scale & Offset
					p = scale * p + testPoint;
					derivative = derivative * abs(scale) + 1;
				}
				//return length(p) / abs(derivative);
				return boxDE(p, float3(3, 10, 10)) / abs(derivative);
			}

			// DISTANCE ESTIMATOR
			float distanceEstimator(float3 position) {

				float3 p = position - float3(0, 0, 6);
				float zoom = 15;
				p /= zoom;

				p -= float3(-1+5, 0.5, 5.5);

				float element1 = mandelboxDE(p) * zoom;

				float element2 = boxDE(position - float3(0.1, -0.25, 1.8), float3(4.0, 0.2, 4.0));

				return min(element1, element2);
			}

			float3 fastSurfaceNormalNearPoint(float3 p, float epsilon) {
				return normalize(float3(
						distanceEstimator(p + float3(epsilon, 0, 0)),
						distanceEstimator(p + float3(0, epsilon, 0)),
						distanceEstimator(p + float3(0, 0, epsilon))
				));
			}

			float3 accurateSurfaceNormalNearPoint(float3 p, float epsilon) {
				return normalize(float3(
						distanceEstimator(p + float3(epsilon, 0, 0)) - distanceEstimator(p - float3(epsilon, 0, 0)),
						distanceEstimator(p + float3(0, epsilon, 0)) - distanceEstimator(p - float3(0, epsilon, 0)),
						distanceEstimator(p + float3(0, 0, epsilon)) - distanceEstimator(p - float3(0, 0, epsilon))
				));
			}



			fixed4 frag (v2f input) : SV_Target {

				// Raymarch parameters
				float maxSteps = 200;
				float maxDistance = 200;
				float travelMultiplier = 1;
				float touchDistanceMultiplier = 0.002;

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

				bool didHitSurface = distanceToSurface <= touchDistance * 1;

				//float3 surfaceNormal = accurateSurfaceNormalNearPoint(rayPosition, touchDistance);

				//stepNumber = maxSteps - stepNumber;
				float brightness = stepNumber/maxSteps;
				if (!didHitSurface) {
					brightness = 1 - brightness;
					brightness = pow(brightness, 1.4);
					return float4(pow(brightness, 2), pow(brightness, 0.9), pow(brightness, 0.7), 1);
				}
				brightness = log(stepNumber) / log(maxSteps);
				brightness = pow(1-brightness, 1);
				//float b = pow(0.5, exp(-1.5*dot(surfaceNormal, float3(0, 1, 0))));
				//brightness = b;//sqrt(brightness * b);
				return float4(brightness, brightness, brightness, 1);
			}
			ENDCG
		}
	}
}
