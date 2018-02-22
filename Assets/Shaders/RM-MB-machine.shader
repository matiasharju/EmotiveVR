// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/RM-MB-spikey-basic"
{
	Properties
	{
		 [NoScaleOffset] _MainTex ("Texture", 2D) = "white" {}
		 //_arvo ("Säätö", color) = color(0, 0, 0, 1) {}
		 _globalTime ("Time", float) = 0.0
		 _iterations ("Iteration Count", int) = 4
		 _baseSpeed ("Global Animation Speed", float) = 0.1
		 _sunLight ("Sunlight", vector) = (1.0, 1.0, 1.0, 1.0)

		 _foldLimit ("Fold Limit", float) = 0.62
		 _foldValue ("Fold Value", float) = 1.36
		 _smallRadius ("Small Radius", float) = 0.5
		 _bigRadius ("Big Radius", float) = 1.0

		 // VR Parameters
		 _rightHandPosition ("Right Hand", vector) = (1.5,0.0,-2.5,0.0)
		 _leftHandPosition ("Left Hand", vector) = (-1.5,0.0,-2.5,0.0)

	}
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 4.0
			#include "UnityCG.cginc"
            #include "DE-Primitives.cginc"
            #include "DE-Operations.cginc"

			float _globalTime; // ei käytössä. ei ehkä tarvettakaan.

			int foldCount;
			float _baseSpeed;
			int _iterations;
			float _foldLimit;
			float _foldValue;
			float _smallRadius;
			float _bigRadius;

            int elementID;
            float3 surfaceColor;
			float4 _sunLight;
			float4 _rightHandPosition;
			float4 _leftHandPosition;

			float3x3 element1Rotation;

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

			float4 trap;
			float mandelboxDE(float3 testPoint, int iterations) {
				float t = 1;//pow(sin(_Time.y * 0.2), 3);
				float scale = -1.48;
				// Orbit traps catching for colors
				float3 w = testPoint / 2.5;
				float m = dot(w,w);
				trap = float4(abs(w),m);
				//

				float foldLimit = _foldLimit; // Typically 1
				float foldValue = _foldValue; //Typically 2
				float smallRadius = _smallRadius;// * (sin(_WorldSpaceCameraPos.x*0.2)*3); //0.3 + 0.2 * t;  // Typically 0.5
				float bigRadius = _bigRadius; // 0.9 + 0.1 * t;  // Typically 1.0

				float derivative = 1.5;
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
					// Orbit traps catching for colors
					if (i < 3) {
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
					if (i%5 == 0) {
						p = scale * p + testPoint;

					}

					// Scale & Offset
					p = scale * p + testPoint;
					derivative = derivative * abs(scale) + 1;
			}
				trap.w *= m;

				return box(p, (p.x)) / abs(derivative);
			}

			// DISTANCE ESTIMATOR
			float distanceEstimator(float3 rayPosition, bool calculatingShadows) {
				float overShoot = 1.0; // pieni luku tekee hurjan tunneliefektin
				float3 p = rayPosition - float3(-40, 0, -50); //
				float zoom = 5;
				p /= zoom;
				//p -= float3(4.3, 0.5, 5.5);

				float playerShadow;

				float an = sin(_Time*20);
				float an2 = sin(40 + _Time * 40);
                float element1 = 10000;
				float h = 20.0;//sin(_Time.y/10) / 2;
				element1Rotation = mul(rotateXY(3.1415/2), rotateYZ(3.1415/2)) ;
				float element2 = mandelboxDE(mul(p + float3(0,-5.5,0), element1Rotation) , _iterations)  * zoom * overShoot;
				float elementSlab = plane(rayPosition - float3(0, -100, 0), float4(0.0, 1.0, 0.00, 0.00));

				float rightHandObject = 10000;//sphere(rayPosition - _WorldSpaceCameraPos - _rightHandPosition + float3(0.0,1.7,0.0), 0.05);

				float frontElement = element1;
				elementID = 1;
				float colorModifier = 1 ;//- smoothstep(-0, 0, sin(20.0 * (p.y)) + sin(20.0 * p.x) + sin(20.0 * p.z)); //pallokuosi

				if (element2 < element1) {
					frontElement = element2;
					elementID = 2;
				}
				// Orbit traps catching for colors
				//trap.b *= m;
				surfaceColor.r = step(0.7, trap.b);
				surfaceColor.g = 0.5*trap.b;
				surfaceColor.b = step(0.1, trap.b);
				surfaceColor.b *= surfaceColor.g;
				//surfaceColor.b += 1 - smoothstep(0.020, 0.022, trap.r);
				surfaceColor.r += 1.1 - smoothstep(0.015, 0.25, trap.b);
				surfaceColor.g += 1 - step(0.02, trap.b);
				surfaceColor.r *= step(0.75, trap.g);

				surfaceColor.g *= step(0.3, surfaceColor.r);
				surfaceColor.b *= step(0.3, surfaceColor.r);

				//
				surfaceColor.r += min(1 - surfaceColor.r, smoothstep(0.9, 0.99, 0.5 + 0.5 * sin(trap.w*0.06 * (mul(p, rotateXY(_Time.x*0.02)).y))));
				//surfaceColor.g += step(0.5, 0.5 + 0.5 * sin(25.0 * (mul(p, rotateXY(_Time*1)).x)));

				if (elementSlab < frontElement) {
					frontElement = elementSlab;// pitäisikö ottaa pois varjojen laskennasta?
						elementID = 3;
						//surfaceColor.r -= min(surfaceColor.g - 0.2, step(0.99, 0.5 + 0.5 * sin(trap.w*0.004)));
				}

				if (rightHandObject < frontElement) {
					frontElement = rightHandObject;
					if (!calculatingShadows) {
						elementID = 4;
						surfaceColor = float3(0.01, 0.01, 0.01);
					}
				}

				float ret = min(elementSlab, element1);
                ret =  min(element2, ret);
				return min(ret, frontElement);
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
				float maxSteps = 150;
				float maxDistance = 600;
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
				while ((stepNumber == 0) || (travelDistance < maxDistance
					&& distanceToSurface > touchDistance
					&& stepNumber < maxSteps)) {
					stepNumber += 1;
					rayPosition = eyePosition + travelDistance * viewDirection;
					distanceToSurface = distanceEstimator(rayPosition, false);
					travelDistance += travelMultiplier * distanceToSurface;
					touchDistance = touchDistanceMultiplier * travelDistance;
				}
				float3 surfaceNormal = accurateSurfaceNormalNearPoint(rayPosition, 0.0001);

				bool didHitSurface = distanceToSurface <= touchDistance * 10;

				float raymarchLight = stepNumber/maxSteps;

				// Rendering the background
				if (!didHitSurface && stepNumber < maxSteps) {
					raymarchLight = 1 - raymarchLight;
					raymarchLight = pow(raymarchLight, 4);
					return float4(
						1.0 * pow(raymarchLight, 2.5),
						1.0 * pow(raymarchLight, 1),
						1.0 * pow(raymarchLight, 1),
						1);
				}
				//float3 normalColor = surfaceNormal.xyz * 0.1;
				float3 normalLight = 1;//surfaceNormal.yyy;// * surfaceNormal.y * surfaceNormal.z;
				// naive ambient occlusion, range 0 = light .. 1 = dark
			    float ambientOcclusion = pow(log(float(stepNumber)) / log(float(maxSteps)), 1.5);
				float ambientLight = 0.02;

				raymarchLight = pow(1 - raymarchLight, 0.75);
				float shadows = ambientOcclusion ;//+ 0.5* softCastShadows(rayPosition);
				shadows = 1.0 * min(1.0, shadows);
				//float surfaceLight = ambientLight + max(0, raymarchLight * surfaceLighting(rayPosition, surfaceNormal) - shadows);
				float surfaceLight = ambientLight + max(0, raymarchLight * (1.0 + 0.0 * surfaceLighting(rayPosition, surfaceNormal) * normalLight) - shadows);
				//return float4(surfaceNormal.xyz * raymarchLight, 1.0);
                // Element colors
				surfaceColor *= surfaceLight;
				//surfaceColor += pow(normalColor,3.1);

				surfaceColor.r += 0.1 * pow(surfaceLight + 0.1,7);
				surfaceColor.g += 0.1 * pow(surfaceLight + 0.1,7);
				surfaceColor.b += 0.1 * pow(surfaceLight + 0.1,7);
                return float4(surfaceColor, 1.0);
			}
			ENDCG
		}
	}
}
