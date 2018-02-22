// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/RM-maksa"
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

			// ^^ Everything before this should be copied to all our shaders.

			float4 trap;
			float mandelboxDE(float3 testPoint, int iterations) {
				float scale = -1.5;

				// Orbit traps catching for colors
				float3 w = testPoint / 2.5;
				float m = dot(w,w);
				trap = float4(abs(w),m);
				//
				float t = pow(sin(_Time.y * _baseSpeed), 3);
				float foldLimit = _foldLimit; // Typically 1
				float foldValue = _foldValue; //Typically 2
				float smallRadius = _smallRadius + 0.2 * t;// * (sin(_WorldSpaceCameraPos.x*0.2)*3); //0.3 + 0.2 * t;  // Typically 0.5
				float bigRadius = _bigRadius + 0.1 * t; // 0.9 + 0.1 * t;  // Typically 1.0
				float derivative = 1;
				float3 p = testPoint;
				float smallRadiusSquared = smallRadius * smallRadius;
				float onePerSmallRadiusSquared = 1 / smallRadiusSquared;
				float bigRadiusSquared = bigRadius * bigRadius;
				float onePerBigRadiusSquared = 1 / bigRadiusSquared;

				for (int i = 0; i < iterations; i++) {

					// Box fold
					if (p.x > foldLimit) p.x = foldValue - p.x;
					else if (p.x < -foldLimit) p.x = -foldValue - p.x;
					if (p.y > foldLimit) p.y = foldValue - p.y;
					else if (p.y < -foldLimit) p.y = -foldValue - p.y;
					if (p.z > foldLimit) p.z = foldValue - p.z;
					else if (p.z < -foldLimit) p.z = -foldValue - p.z;

					p = mul(rotateXY(0.902), p);
					// Orbit traps catching for colors
					if (i > 0) {
						trap = min( trap, float4(abs(p),m) );
					}
					//
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
					if (i < 4) {
						m = dot(p,p);
					}
				}
				//return length(p) / abs(derivative);

				// Orbit traps catching for colors
				trap.b *= m;
				trap.r *= m;
				surfaceColor.r = 1 - step(0.3, trap.r);
				//surfaceColor.r = 1 - step(0.7, trap.b);
				surfaceColor.r += 1 - smoothstep(0.020, 0.022, trap.r);
				surfaceColor.g = 1 - smoothstep(0.015, 0.025, trap.r);
				//surfaceColor.g += 1 - step(0.02, trap.b);
				surfaceColor.b = 1 - smoothstep(0.015, 0.025, trap.r);
				//surfaceColor.b += 1 - step(0.02, trap.b);
				//
				return box(p, float3(1.2, 1.2, 1.2)) / abs(derivative) ;
			}

			// DISTANCE ESTIMATOR
			float distanceEstimator(float3 rayPosition, bool calculateShadows) {

				float overShoot = 1;
				float3 p = mul( (rayPosition - _objectOffset - _worldOffset), _worldMatrix); //
				float zoom = 20;
				p /= zoom;
				float element1 = mandelboxDE(p, _iterations) * zoom * overShoot;
				//surfaceColor *= float3(0.95, 0.1, 0.1);

				return element1;
			}

			#include "DE-SurfaceNormals.cginc"

			fixed surfaceLighting (float3 rayPosition, float3 surfaceNormal) {
				float sunLight = max(0, dot(surfaceNormal, normalize(_sunLight.xyz)));
				//sunLight = step(0.4, sunLight); // Kovaa valaistusta varten
				sunLight = pow(sunLight, 0.1);  // Vahvistaa valon
				return sunLight;
			}

			fixed hardCastShadows(float3 p) {
				float lightDistanceFromSurface = 50; // just put some large value so we enter the iteration
		            //float3 cameraPosition = rayPosition - viewDirection * rayDistance;
		            float3 lightDirection = normalize(_sunLight.xyz);
		            float lightTravelDistance = 0.01;
		            while (lightTravelDistance < 50) {
		                lightDistanceFromSurface = distanceEstimator(p + lightDirection * lightTravelDistance, true);
						if (lightDistanceFromSurface < 0.001) {
							return 1.0;
						}
		                lightTravelDistance += lightDistanceFromSurface;
		            }
				return 0.0;
			}

			fixed4 frag (v2f input) : SV_Target {

				// Raymarch parameters
				float maxSteps = 200;
				float maxDistance = 200; //2000
				float travelMultiplier = 1;
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
					distanceToSurface = distanceEstimator(rayPosition, false);
					travelDistance += travelMultiplier * distanceToSurface;
					touchDistance = touchDistanceMultiplier * travelDistance;
				}
				float3 surfaceNormal = accurateSurfaceNormalNearPoint(rayPosition, 0.001);

				bool didHitSurface = distanceToSurface <= touchDistance * 10; //10

				// naive ambient occlusion, range 0 = light .. 1 = dark
				float ambientOcclusion = pow(log(float(stepNumber)) / log(float(maxSteps)), 1.5);
				float shadows = ambientOcclusion ;//+ 0.5* softCastShadows(rayPosition);

				float raymarchLight = stepNumber/maxSteps;

				if (!didHitSurface) {
					raymarchLight = 1 - raymarchLight;
					raymarchLight = pow(raymarchLight, 6.4);
					return float4(
						pow(raymarchLight, 2),
						pow(raymarchLight, 1.25),
						pow(raymarchLight, 1.0),
						1);
				}
				float ambientLight = 0.0;
				raymarchLight = pow(1 - raymarchLight, 0.75);
				float surfaceLight = ambientLight + max(0, raymarchLight * (0.9 + 0.1 * surfaceLighting(rayPosition, surfaceNormal)) - shadows);
				float specular = surfaceColor.r * surfaceColor.g * surfaceColor.b;

				surfaceColor *= surfaceLight;
				surfaceColor += specular;
				surfaceColor.r += 0.1 * pow(surfaceLight + 0.1,4);
				//surfaceColor.g += 0.1 * pow(surfaceLight + 0.1,6);
				//surfaceColor.b += 0.1 * pow(surfaceLight + 0.1,8);
				//surfaceColor.r -= 0.4 * pow(surfaceLight - 0.1,1.2);
				surfaceColor.g -= 0.4 * pow(surfaceLight - 0.1,1.2);
				surfaceColor.b -= 0.4 * pow(surfaceLight - 0.1,1.2);
				
                return float4(surfaceColor, 1.0);
			}
			ENDCG
		}
	}
}
