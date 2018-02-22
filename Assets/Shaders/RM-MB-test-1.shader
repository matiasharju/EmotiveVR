// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/RM-MB-iso-3"
{
	Properties
	{
		 [NoScaleOffset] _MainTex ("Texture", 2D) = "white" {}
		 //_arvo ("Säätö", color) = color(0, 0, 0, 1) {}
		 _globalTime ("Time", float) = 0.0
		 _iterations ("Iteration Count", int) = 4
		 _baseSpeed ("Global Animation Speed", float) = 0.1
		 _derivative ("Fractal Derivative", range (0.0, 4.0)) = 1.0
		 _overShoot ("DE Overshoot", range (0.0, 5.0)) = 1.0
		 _mandelbulbPower ("Mandelbulb Power", range (0.0, 16.0)) = 8.0

	}
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
            #include "DE-Primitives.cginc"
            #include "DE-Operations.cginc"

			float _globalTime; // ei käytössä. ei ehkä tarvettakaan.

			int foldCount;
			float _baseSpeed;
			int _iterations;
			float _derivative;
			float _overShoot;
			float _mandelbulbPower;

            int elementID;
            float3 surfaceColor;

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
				float scale = -1;

				float t = pow(sin(_Time.y * _baseSpeed *  0.2), 3);
				float smallRadius = 0.7 + 0.2 * t;
				float bigRadius = 1.0 + 0.1 * t;
				float foldLimit = 1; // Typically 1
				float foldValue = 2; //Typically 2
				float derivative = _derivative; // Was 1.0
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
				return torus(p, float2(0.5, 0.1)) / abs(derivative);
			}

			float mandelbulbHvidtfeldts (float3 p, int iterations) {
				//http://blog.hvidtfeldts.net/index.php/2011/09/distance-estimated-3d-fractals-v-the-mandelbulb-different-de-approximations/
				float3 z = p/10;
				float dr = 1.0;
				float r = 0.0;

				float Power = 8.0;

				for (int i = 0; i < iterations ; i++) {
					r = length(z);
					//if (r>Bailout) break;

					// convert to polar coordinates
					dr = pow( r, Power-1.0) * Power * dr + 1.0;
					float theta = acos(z.z / r);
					float phi = atan(z.y/z.x);

					// scale and rotate the point
					float zr = pow(r, Power);
					theta = theta * Power;
					phi = phi * Power;

					// convert back to cartesian coordinates
					z = zr * float3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
					z += p;
				}
				return 0.5 * log(r) * r/dr;
			}

			float mandelbulb(float3 p, int iterations) {
				float3 w = p / 2.5;
				float m = dot(w,w);

				float4 trap = float4(abs(w),m);
				float dz = _derivative;
				int power = _mandelbulbPower;

				for( int i=0; i < iterations; i++ )
				{
					float m2 = m*m;
					float m4 = m2*m2;
					dz = power*sqrt(m4*m2*m)*dz + 1.0;

					float x = w.x; float x2 = x*x; float x4 = x2*x2;
					float y = w.y; float y2 = y*y; float y4 = y2*y2;
					float z = w.z; float z2 = z*z; float z4 = z2*z2;

					float k3 = x2 + z2;
					float k2 = 1/sqrt( k3*k3*k3*k3*k3*k3 ); // alkuperäisessä on 7 k3:sta
					float k1 = x4 + y4 + z4 - 6.0*y2*z2 - 6.0*x2*y2 + 2.0*z2*x2;
					float k4 = x2 - y2 + z2;

					w.x = p.x +  64.0*x*y*z*(x2-z2)*k4*(x4-6.0*x2*z2+z4)*k1*k2;
					w.y = p.y + -16.0*y2*k3*k4*k4 + k1*k1;
					w.z = p.z +  -8.0*y*k4*(x4*x4 - 28.0*x4*x2*z2 + 70.0*x4*z4 - 28.0*x2*z2*z4 + z4*z4)*k1*k2;

					trap = min( trap, float4(abs(w),m) );

					m = dot(w,w);
					if( m > 4.0 )
					break;
				}
				trap.r = m;
				surfaceColor = pow(trap, 0.2);

				return 0.05*log(m)*sqrt(m)/dz;
			}

			// DISTANCE ESTIMATOR
			float distanceEstimator(float3 position) {

				float overShoot = _overShoot; // default 1.0 - pienempi luku tekee hurjan tunneliefektin
				float3 p = position - float3(-40, 0, -50); //
				float zoom = 15;
				p /= zoom;
				p -= float3(4.3, 0.5, 5.5);
                float element1 = 10000; // big number means nothing
				//float element2 = mandelboxDE(p, 3) * zoom * overShoot;
				float element2 = mandelbulb(p, _iterations) * zoom * overShoot;
				float elementSlab = box(position - float3(0.1, -0.25, 1.8), float3(4.0, 0.2, 4.0));
                float frontElement = element1;

                elementID = 1;
                //surfaceColor = float3(0.75, 0.55, 0.0);
				float colorModifier = 1 - smoothstep(-0, 0, sin(20.0 * (p.y)) + sin(20.0 * p.x) + sin(20.0 * p.z)); //pallokuosi

                if (element2 < element1) {
                    frontElement = element2;
                    elementID = 2;
                    //surfaceColor = float3(1.0, 0.0, 0.0);
                    float h = sin(_Time.y/10) / 2;
                    //float colorModifier = 1 - min(p.y < h ? 1 : 0, 2 * smoothstep(-0.7, -0.65, sin(200.0 * (p.y ))-1.2));// * sin(20.0 * p.x) * sin(20.0 * p.z));
                    //float colorModifier = 1 - min(p.y > h ? 1 : 0, 2 * smoothstep(-0.1+h, 0.1+h, sin(20.0 * (p.y + (p.x) + p.z * h))));// * sin(20.0 * p.x) * sin(20.0 * p.z));
                    //float colorModifier = 1 - 2 * smoothstep(-0.1+h, 0.1+h, sin(20.0 * (p.y + p.z * h)) * sin(20.0 * p.x) * sin(20.0 * p.z));
                    colorModifier = 1 ;//- 2 * smoothstep(-0.02, 0.02, sin(20.0 * (p.y + p.x)));
                }
				//surfaceColor = float3(1.0, 1.0 * colorModifier, 1.0 * colorModifier);

                if (elementSlab < frontElement) {
                    elementID = 3;
                    surfaceColor = float3(0.01, 0.01, 0.01);
                    return elementSlab;
                }

                return smin(element1, element2, 1.5);
                //return min(element1, element2);
			}
			//#include "DE-SurfaceNormals.cginc"
            // Kiiltoja yms varten. Ei käytössä nyt.
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
				float maxSteps = 90;
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
				float previousDistanceToSurface;
				float touchDistance;

				while ((stepNumber == 0) || (travelDistance < maxDistance &&
					distanceToSurface > touchDistance &&
					stepNumber < maxSteps)) {
						stepNumber += 1;
						rayPosition = eyePosition + travelDistance * viewDirection;
						previousDistanceToSurface = distanceToSurface;
						distanceToSurface = distanceEstimator(rayPosition);
						/*if (distanceToSurface > touchDistance) {  //testaa keskiarvoa edellisen kanssa
							distanceToSurface = (previousDistanceToSurface + distanceToSurface) / 2;
						}*/

						travelDistance += travelMultiplier * distanceToSurface;
						touchDistance = touchDistanceMultiplier * travelDistance;
				}

				bool didHitSurface = distanceToSurface <= touchDistance * 10;

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
                return float4(surfaceColor * brightness, 1.0);

                //if (elementID == 1) {
                //    return float4(brightness, brightness, brightness, 1) * surfaceColor;
                //} else if (elementID == 3) {
                //    return float4(brightness * 0.1, brightness * 0.1, brightness * 0.71, 1);
                //} else {
                //    return float4(brightness * 0.81, brightness * 0.01, brightness * 0.01, 1);
                //}
			}
			ENDCG
		}
	}
}
