// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/RM-Limbo"
{
	Properties
	{
		[NoScaleOffset] _MainTex ("Texture", 2D) = "white" {}
		_globalTime ("Time", float) = 0.0
		_baseSpeed ("Global Animation Speed", float) = 0.1
		_worldOffset ("World-Camera Offset", vector) = (0, 0 ,0 ,0)
		_objectOffset ("Main object Offset", vector) = (0, 0 ,0 ,0)
		_worldRotation ("World-Camera Rotation", vector) = (0, 0 ,0 ,0)

		// Colors
		_color1 ("Color 1", color) = (1, 0, 0, 1)
		_color2 ("Color 2", color) = (0, 1, 0, 1)
		_color3 ("Color 3", color) = (0, 0, 1, 1)
		_sunLight ("Sunlight", vector) = (1.0, 1.0, 1.0, 1.0)

		// Fractals
		_iterations ("Iteration Count", range(1, 100)) = 4
		_foldLimit ("Fold Limit", range(-4.0, 4.0)) = 1.0
		_foldValue ("Fold Value", range(-4.0, 4.0)) = 2.0
		_smallRadius ("Small Radius", range(-4.0, 4.0)) = 0.5
		_bigRadius ("Big Radius", range(-4.0, 4.0)) = 1.0

		// KIFS Rotations
		_foldRotateXY ("foldRotateXY", float) = 0.0
		_foldRotateXZ ("foldRotateXZ", float) = 0.0
		_foldRotateYZ ("foldRotateYZ", float) = 0.0

		// Generic parameters
		_knob1 ("Knob 1", float) = 0.0
		_knob2 ("Knob 2", float) = 0.0
		_knob3 ("Knob 3", float) = 0.0
		_knob4 ("Knob 4", float) = 0.0
		_knob5 ("Knob 5", float) = 0.0
		_knob6 ("Knob 6", float) = 0.0
		_knob7 ("Knob 7", float) = 0.0
		_knob8 ("Knob 8", float) = 0.0

	}
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			//#pragma target 4.0
			#include "UnityCG.cginc"
			#include "DE-Primitives.cginc"
			#include "DE-Operations.cginc"

			float _globalTime, _baseSpeed;
			float4 _worldOffset, _objectOffset, _worldRotation;
			float4x4 _worldMatrix;
			fixed4 _color1, _color2, _color3;
			float4 _sunLight;
			int _iterations;
			float _foldLimit, _foldValue, _smallRadius, _bigRadius;
			float _foldRotateXY, _foldRotateXZ, _foldRotateYZ;
			float _knob1, _knob2, _knob3, _knob4, _knob5, _knob6, _knob7, _knob8;

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
				output.vertex = UnityObjectToClipPos(v.vertex);
				output.uv = v.uv;
				output.viewDirection = WorldSpaceViewDir(v.vertex);
				return output;
			}

			int elementID;
			fixed3 surfaceColor;
			float4 trap;
			// ^^ Everything before this should be copied to all our shaders.

			float mandelboxDE(float3 testPoint, int iterations) {
				float scale = -1;

				float t = pow(sin(_Time.y * 0.2), 3);
				float smallRadius = 0.7 + 0.2 * t;
				float bigRadius = 1.0 + 0.1 * t;
				float foldLimit = 1; // Typically 1
				float foldValue = 2; //Typically 2
				float derivative = 1;
				float3 p = testPoint;
				float smallRadiusSquared = smallRadius * smallRadius;
				float onePerSmallRadiusSquared = 1 / smallRadiusSquared;
				float bigRadiusSquared = bigRadius * bigRadius;
				float onePerBigRadiusSquared = 1 / bigRadiusSquared;

				// Orbit traps catching for colors
				float3 w = testPoint / 2.5;
				float m = dot(w,w);
				trap = float4(abs(w),m);
				//
				for (int i = 0; i < iterations; i++) {
					// Orbit traps catching for colors
					if (i > 0) {
						trap = min( trap, float4(abs(p),m) );
					}
					//

					// Box fold
					if (p.x > foldLimit) p.x = foldValue - p.x;
					else if (p.x < -foldLimit) p.x = -foldValue - p.x;
					if (p.y > foldLimit) p.y = foldValue - p.y;
					else if (p.y < -foldLimit) p.y = -foldValue - p.y;
					if (p.z > foldLimit) p.z = foldValue - p.z;
					else if (p.z < -foldLimit) p.z = -foldValue - p.z;
					// Special sphere fold
					float lengthSquared = dot(p, p);
					if (lengthSquared < smallRadiusSquared) {
						derivative *= onePerSmallRadiusSquared;
						p *= onePerSmallRadiusSquared;
					} else if (lengthSquared < bigRadiusSquared) {
						derivative *= onePerBigRadiusSquared / lengthSquared;
						p *= onePerBigRadiusSquared / lengthSquared;
					}
					// Scale & Offset
					p = scale * p + testPoint;
					derivative = derivative * abs(scale) + 1;
				}
				trap.w = m;
				//return length(p) / abs(derivative);
				return torus(p, float2(0.3, 0.1) * _knob7) / abs(derivative);
			}

			// DISTANCE ESTIMATOR
			float distanceEstimator(float3 position, bool notusedanymore) {

				float overShoot = 1.0; // pieni luku tekee hurjan tunneliefektin
				float3 p = position; //
				float zoom = 15;
				p /= zoom;
                float element1 = 10000; // big number means nothing
                float element2 = mandelboxDE(p, _iterations) * zoom * overShoot;
				float elementSlab = box(position, float3(4.0, 0.2, 4.0));
                float frontElement = element1;

                elementID = 1;

                if (element2 < element1) {
                    frontElement = element2;
                    elementID = 2;
                    surfaceColor = float3(1.0, 1.0, 1.0);
                }

                if (elementSlab < frontElement) {
                    elementID = 3;
                    surfaceColor = float3(0.01, 0.01, 0.01);
                    return elementSlab;
                }

                return smin(element1, element2, 1.5);
                //return min(element1, element2);
			}
			#include "DE-SurfaceNormals.cginc"

			fixed surfaceLighting (float3 rayPosition, float3 surfaceNormal) {
				float sunLight = max(0, dot(surfaceNormal, normalize(_sunLight.xyz)));
				//sunLight = step(0.4, sunLight); // Kovaa valaistusta varten
				sunLight = pow(sunLight, 0.1);  // Vahvistaa valon
				return sunLight;
			}

			fixed4 frag (v2f input) : SV_Target {

				// Raymarch parameters
				float maxSteps = 240;
				float maxDistance = 200;
				float travelMultiplier = 1;
				float touchDistanceMultiplier = 0.001;

				// Raymarch code
				float3 eyePosition = _WorldSpaceCameraPos;
				float3 viewDirection = -normalize(input.viewDirection);
				float stepNumber = 0;
				float travelDistance = 0.0;  // Normally 0.0 but bigger number creates protective bubble around the camera
				float3 rayPosition;
				float distanceToSurface;
				float touchDistance;
				while ((stepNumber == 0) || (travelDistance < maxDistance && distanceToSurface > touchDistance && stepNumber < maxSteps)) {
					stepNumber += 1;
					rayPosition = eyePosition + travelDistance * viewDirection;
					distanceToSurface = distanceEstimator(rayPosition, true);
					travelDistance += travelMultiplier * distanceToSurface;
					touchDistance = touchDistanceMultiplier * travelDistance;
				}
				float3 surfaceNormal = accurateSurfaceNormalNearPoint(rayPosition, 0.001);

				bool didHitSurface = distanceToSurface <= touchDistance * 10;
				float raymarchLight = stepNumber/maxSteps;

				// Rendering the background
				if (!didHitSurface && stepNumber < maxSteps) {
					raymarchLight = 1 - raymarchLight;
					raymarchLight = pow(raymarchLight, 1.4);
					return float4(
						1.0 - 1.0 * pow(raymarchLight,7.1),
						pow(raymarchLight, 0.4) * 0.7,
						pow(raymarchLight, 0.9) * 1.0,
						1);
				}

				// naive ambient occlusion, range 0 = light .. 1 = dark
			    float ambientOcclusion = pow(log(float(stepNumber)) / log(float(maxSteps)), 1.5);

				fixed4 normalColor = float4(surfaceNormal.xyz, 1);
				normalColor = 1 - smoothstep(0.2, 0.8, normalColor);//smoothstep(0.25, 0.45, normalColor);

				float brightness = stepNumber/maxSteps;
				if (!didHitSurface) {
					brightness = 1 - brightness;
					brightness = pow(brightness, 1.4);
					return float4(pow(brightness, 2), pow(brightness, 0.9), pow(brightness, 0.7), 1);
				}
				brightness = log(stepNumber) / log(maxSteps);
				brightness = pow(1-brightness, 1);
				brightness = pow(brightness, exp(-(brightness*2)));

                // Element colors
                return float4(surfaceColor * brightness * normalColor , 1.0);
			}
			ENDCG
		}
	}
}
