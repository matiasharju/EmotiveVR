// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/RM-Pioneer"
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
				float3 p = mul(rotateXY(0), testPoint);
				float t = 1;//pow(sin(_Time.y * 0.2), 3);
				float scale = 2;

				// Orbit traps catching for colors
				float3 w = testPoint / 2.5;
				float m = dot(w,w);
				trap = float4(abs(w),m);
				trap.w = m;
				//
				iterations = max(1, iterations);
				float foldLimit = _foldLimit; // Typically 1
				float foldValue = _foldValue; //Typically 2
				float smallRadius = _smallRadius;  // Typically 0.5
				float bigRadius = _bigRadius; // 0.9 + 0.1 * t;  // Typically 1.0

				float derivative = 1;
				float smallRadiusSquared = smallRadius * smallRadius;
				float onePerSmallRadiusSquared = 1 / smallRadiusSquared;
				float bigRadiusSquared = bigRadius * bigRadius;
				float onePerBigRadiusSquared = 1 / bigRadiusSquared;

				// translations. meaningful values probably between -1 and 0 (some -2 or +1 might be ok, too)
			    float s1 = _knob1;//-0.2;// + 0.2 * sin(_Time.y);
			    float t1 = _knob2;//-0.4;

			    float s2 = _knob3;//-0.8;
			    float t2 = _knob4;//-0.5;

			    float s3 = _knob5;//-0.6;
			    float t3 = _knob6;//-0.9;

				float mm = 1.4; // meaningful values between 1.1 and 1.3
				float foldAngle1 = 3.1415 * 0.01 * _foldRotateXY;
				float foldAngle2 = 3.1415 * 0.01 * _foldRotateXZ;
				float foldAngle3 = 3.1415 * 0.01 * _foldRotateYZ;
				float foldAngle4 = 1.75 * foldAngle3;
				float3 foldNormal = float3(sin(foldAngle1), cos(foldAngle1), 0);
				float foldNormal1 = float3(sin(foldAngle1), cos(foldAngle1), 0);
				float foldNormal2 = float3(sin(foldAngle2), cos(foldAngle2), 0);
				float foldNormal3 = float3(sin(foldAngle3), cos(foldAngle3), 0);
				int iterationModulo = 7;
				for (int i = 0; i < iterations; i++) {
			        p -= 2.0 * min(0.0, dot(p, foldNormal)) * foldNormal; // a fold in a general plane with normal n
			        float s;
			        float t = 0;

		        if (i % iterationModulo == 0) {
			            s = s1;
			            t = t1;
			            p = float3(p.y, p.z, p.x);
						p -= 2.0 * min(0.0, dot(p, foldNormal1)) * foldNormal1; // a fold in a general plane with normal
						//p = opU(sphere(p, 1), box(p,1));
			        } else if (i % iterationModulo == 1) {
			            s = s2;
			            t = t2;
			            p = float3(p.y, p.z, p.x);
			            p -= 0.2 * min(0.0, dot(p, foldNormal2)) * foldNormal2; // a fold in a general plane with normal
						//p = opU(sphere(p, 1), box(p,1));

			        } else if (i % iterationModulo == 2) {
			            s = s3;
			            t = t3;
			            p = float3(p.z, p.x, p.y);
						p -= 2.0 * min(0.0, dot(p, foldNormal3)) * foldNormal3; // a fold in a general plane with normal
						//p = opU(sphere(p, 1), box(p,1));

					}
					// Orbit traps catching for colors
					if (i > 0) {
						trap = min( trap, float4(abs(p),m) );
					}
					//

			        p += float3(0, s, t);
			        scale *= mm;
			        p *= mm;

					p.x += 1;

					if (i % iterationModulo >= 3) {
					// Box fold
						if (p.x > foldLimit)  		p.x = foldValue - p.x;
						else if (p.x < -foldLimit)  p.x = -foldValue - p.x;
						if (p.y > foldLimit)  		p.y = foldValue - p.y;
						else if (p.y < -foldLimit) 	p.y = -foldValue - p.y;
						if (p.z > foldLimit) 		p.z = foldValue - p.z;
						else if (p.z < -foldLimit) 	p.z = -foldValue - p.z;
					}

					p = float3(p.y, p.x, p.z);

					// Scale & Offset

					//p = scale * p + testPoint;
					derivative = derivative * abs(scale) + 1;
				}

				//return length(p) / scale;
				//return opU(element1, element2);
				return box(p, float3(0.1, 2, 2)*_knob7) / scale;

			}

			// DISTANCE ESTIMATOR
			float distanceEstimator(float3 rayPosition, bool calculatingShadows) {
				float overShoot = 1.0; // pieni luku tekee hurjan tunneliefektin
				float3 p = rayPosition - _objectOffset - _worldOffset - float3(0, _knob8, 0); //
				float zoom = 15;
				p /= zoom;

				float element1 = 10000;
				float element2 = mandelboxDE(p , _iterations) * zoom * overShoot;
				element1 = 10000;
				float elementSlab = plane(rayPosition - _worldOffset, float4(0.0, 1.0, 0.00, 0.00));

                float frontElement = element1;
				elementID = 1;
                surfaceColor = _color1;

                if (element2 < element1) {
                    frontElement = element2;
                    elementID = 2;
					surfaceColor = fixed3(0, 12, 41)/255;

					surfaceColor += 1 - 0.96 * step(0.05, trap.x);
                }

                if (elementSlab < frontElement) {
					frontElement = elementSlab;
                    elementID = 3;
                    surfaceColor = _color3;
					surfaceColor -= 1 - 0.96 * step(0.05, trap.x);
					surfaceColor -= 1 - 0.96 * step(0.05, trap.y);
					surfaceColor -= 1 - 0.96 * step(0.05, trap.z);

                }

				float ret = min(elementSlab, element1);
				return smin(ret, element2, 5.0);
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
				float maxSteps = 300;
				float maxDistance = 500;
				float travelMultiplier = 1;
				float touchDistanceMultiplier = 0.001;

				// Raymarch code
				float3 eyePosition = _WorldSpaceCameraPos;
				float3 viewDirection = -normalize(input.viewDirection);
				float stepNumber = 0;
				float travelDistance = 0.1;  // Normally 0.0 but bigger number creates protective bubble around the camera
				float3 rayPosition;
				float distanceToSurface;
				float touchDistance;
				while ((stepNumber == 0) || (travelDistance < maxDistance
					&& distanceToSurface > touchDistance
					&& stepNumber < maxSteps)) {
					stepNumber += 1;
					rayPosition = eyePosition + travelDistance * viewDirection;
					distanceToSurface = distanceEstimator(rayPosition, false);
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
				float ambientLight = 0.01;
				float shadows = ambientOcclusion;
				shadows = 1.0 * min(1.0, shadows);
				raymarchLight = pow(1 - raymarchLight, 0.75);
				float surfaceLight = ambientLight + max(0, raymarchLight * (0.7 + 0.3 * surfaceLighting(rayPosition, surfaceNormal)) - shadows);
				fixed3 normalColor = surfaceNormal.xyz;
                // Element colors
				surfaceColor *= surfaceLight;
				//surfaceColor *= 1 - 0.2 * pow(normalColor, 3);
				surfaceColor.r += 0.1 * pow(surfaceLight + 0.1,7);
				surfaceColor.g += 0.1 * pow(surfaceLight + 0.1,7);
				surfaceColor.b += 0.1 * pow(surfaceLight + 0.1,7);
				float specularThreshold = 0.3;
				fixed3 fakeSpecular = max(smoothstep(specularThreshold, 1, surfaceColor.r), max(smoothstep(specularThreshold, 1, surfaceColor.g), smoothstep(specularThreshold, 1, surfaceColor.b)));
                return fixed4(surfaceColor + fakeSpecular, 1.0);

			}
			ENDCG
		}
	}
}
