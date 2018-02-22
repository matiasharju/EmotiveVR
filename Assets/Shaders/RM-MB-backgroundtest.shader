// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

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


			float mandelboxDE(float3 testPoint, int iterations) {
				float t = 1;//pow(sin(_Time.y * 0.2), 3);
				float scale = 2;

				float foldLimit = _foldLimit; // Typically 1
				float foldValue = _foldValue; //Typically 2
				float smallRadius = _smallRadius;// * (sin(_WorldSpaceCameraPos.x*0.2)*3); //0.3 + 0.2 * t;  // Typically 0.5
				float bigRadius = _bigRadius; // 0.9 + 0.1 * t;  // Typically 1.0

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
				//return length(p) / abs(derivative);
				return box(p, (0.1, 1.1, 4.1)) / abs(derivative);
			}

			// DISTANCE ESTIMATOR
			float distanceEstimator(float3 rayPosition, bool calculatingShadows) {
				float overShoot = 1.0; // pieni luku tekee hurjan tunneliefektin
				float3 p = rayPosition - float3(-40, 0, -50); //
				float zoom = 15;
				p /= zoom;
				//p -= float3(4.3, 0.5, 5.5);

				float playerShadow;

				float an = sin(_Time*20);
				float an2 = sin(40 + _Time * 40);
                float element1 = sphere(rayPosition - float3(-16.0 - 0*an2, 1*an + 1, 18 + 0*an2), 4);
				float h = 20.0;//sin(_Time.y/10) / 2;

                float element2 = mandelboxDE(p + float3(0,-5.5,0), _iterations) * zoom * overShoot ;//+ min(p.y < h ? 1 : 0, 0.03 * smoothstep(-0.7, -0.65, sin(400.0 * (p.y ))-1.2));
				float elementSlab = plane(rayPosition - float3(0, -4, 0), float4(0.0, 1.0, 0.00, 0.00));

				float rightHandObject = 10000;//sphere(rayPosition - _WorldSpaceCameraPos - _rightHandPosition + float3(0.0,1.7,0.0), 0.05);

                float frontElement = element1;
				if (!calculatingShadows) {
					elementID = 1;
                	surfaceColor = float3(0.95, 0.0, 0.0);
				}
				float colorModifier = 1 ;//- smoothstep(-0, 0, sin(20.0 * (p.y)) + sin(20.0 * p.x) + sin(20.0 * p.z)); //pallokuosi

                if (element2 < element1) {
                    frontElement = element2;
					if (!calculatingShadows) {
                    	elementID = 2;

                    //surfaceColor = float3(1.0, 0.0, 0.0);
                    float h = 20.0;//sin(_Time.y/10) / 2;
                    float colorModifier = 1 ;//- min(p.y < h ? 1 : 0, 2 * smoothstep(-0.7, -0.65, sin(200.0 * (p.y ))-1.2));// * sin(20.0 * p.x) * sin(20.0 * p.z));
                    //float colorModifier = 1 - min(p.y > h ? 1 : 0, 2 * smoothstep(-0.1+h, 0.1+h, sin(20.0 * (p.y + (p.x) + p.z * h))));// * sin(20.0 * p.x) * sin(20.0 * p.z));
                    //float colorModifier = 1 ;//- 0.5 * smoothstep(0.5+h, 0.7+h, sin(40.0 * (p.y + p.z * h)) * sin(40.0 * p.x) * sin(40.0 * p.z));
                    //colorModifier = 1 - 0.96 * step(0, sin(125.0 * (p.y)));
						surfaceColor = float3(1.0 * colorModifier, 0.35 * (1 * colorModifier), 0.0 * colorModifier);
					}
                }

                if (elementSlab < frontElement) {
					frontElement = elementSlab;// pitäisikö ottaa pois varjojen laskennasta?
					if (!calculatingShadows) {
                    	elementID = 3;
                    	surfaceColor = float3(1.0, 1.0, 0.9);
					}
                }

				if (rightHandObject < frontElement) {
					frontElement = rightHandObject;
					if (!calculatingShadows) {
						elementID = 4;
						surfaceColor = float3(0.01, 0.01, 0.01);
					}
				}

				if (calculatingShadows) {
					float playerBodyShadow = ellipsoid(rayPosition - _WorldSpaceCameraPos, float3(1.0, 2.0, 1.0));
					if (playerBodyShadow < frontElement) {
						return playerBodyShadow;
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

			fixed softCastShadows(float3 p) {
				float shadowHardness =90;
				float shadow = 1.0;
				float lightDistanceFromSurface = 50; // just put some large value so we enter the iteration
		            float3 lightDirection = normalize(_sunLight.xyz);
		            float lightTravelDistance = 0.01;
		            while (lightTravelDistance < 50) {
		                lightDistanceFromSurface = distanceEstimator(p + lightDirection * lightTravelDistance, true);
						if (lightDistanceFromSurface < 0.001) {
							return 1.0;
						}
						shadow = min(shadow, shadowHardness * lightDistanceFromSurface / lightTravelDistance);
		                lightTravelDistance += lightDistanceFromSurface;

		            }
				return 1 - shadow;
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

			#include "FX-Textures.cginc"

			fixed4 frag (v2f input) : SV_Target {
				// Raymarch parameters
				float maxSteps = 200;
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
					raymarchLight *= swirlingClouds(((viewDirection.xz)));
					//return raymarchLight * float4(0.75 - input.uv.y, 1 - input.uv.y, 1 - input.uv.y, 1);
					return float4(1.0 * pow(raymarchLight,4.1), pow(raymarchLight, 1.9), pow(raymarchLight, 1.9), 1);
				}

				// naive ambient occlusion, range 0 = light .. 1 = dark
			    float ambientOcclusion = pow(log(float(stepNumber)) / log(float(maxSteps)), 1.5);
				float ambientLight = 0.02;

				//raymarchLight = log(stepNumber) / log(maxSteps);
				raymarchLight = pow(1 - raymarchLight, 0.75);
				float shadows = ambientOcclusion ;//+ 0.5* softCastShadows(rayPosition);
				shadows = 1.0 * min(1.0, shadows);
				//float surfaceLight = ambientLight + max(0, raymarchLight * surfaceLighting(rayPosition, surfaceNormal) - shadows);
				float surfaceLight = ambientLight + max(0, raymarchLight * (0.8 + 0.2 * surfaceLighting(rayPosition, surfaceNormal)) - shadows);
				//return float4(normal.xyz * raymarchLight, 1.0);
                // Element colors
				surfaceColor *= surfaceLight;
				surfaceColor.r += 0.1 * pow(surfaceLight + 0.1,7);
				surfaceColor.g += 0.1 * pow(surfaceLight + 0.1,7);
				surfaceColor.b += 0.1 * pow(surfaceLight + 0.1,7);
                return float4(surfaceColor, 1.0);

                //if (elementID == 1) {
                //    return float4(raymarchLight.xxx, 1) * surfaceColor;
                //} else if (elementID == 3) {
                //    return float4(raymarchLight * 0.1, raymarchLight * 0.1, raymarchLight * 0.71, 1);
                //} else {
                //    return float4(raymarchLight * 0.81, raymarchLight * 0.01, raymarchLight * 0.01, 1);
                //}
			}
			ENDCG
		}
	}
}
