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

			// DISTANCE ESTIMATOR
			float distanceEstimator(float3 position) {

				float overShoot = 1.0; // pieni luku tekee hurjan tunneliefektin
				float3 p = position - float3(-40, 0, -50); //
				float zoom = 15;
				p /= zoom;
				p -= float3(4.3, 0.5, 5.5);
                float element1 = 10000; // big number means nothing
                float element2 = mandelboxDE(p, 3) * zoom * overShoot;
				float elementSlab = box(position - float3(0.1, -0.25, 1.8), float3(4.0, 0.2, 4.0));
                float frontElement = element1;

                elementID = 1;
                surfaceColor = float3(0.75, 0.55, 0.0);
				float colorModifier = 1 - smoothstep(-0, 0, sin(20.0 * (p.y)) + sin(20.0 * p.x) + sin(20.0 * p.z)); //pallokuosi

                if (element2 < element1) {
                    frontElement = element2;
                    elementID = 2;
                    surfaceColor = float3(1.0, 0.0, 0.0);
                    float h = sin(_Time.y/10) / 2;
                    //float colorModifier = 1 - min(p.y < h ? 1 : 0, 2 * smoothstep(-0.7, -0.65, sin(200.0 * (p.y ))-1.2));// * sin(20.0 * p.x) * sin(20.0 * p.z));
                    //float colorModifier = 1 - min(p.y > h ? 1 : 0, 2 * smoothstep(-0.1+h, 0.1+h, sin(20.0 * (p.y + (p.x) + p.z * h))));// * sin(20.0 * p.x) * sin(20.0 * p.z));
                    //float colorModifier = 1 - 2 * smoothstep(-0.1+h, 0.1+h, sin(20.0 * (p.y + p.z * h)) * sin(20.0 * p.x) * sin(20.0 * p.z));
                    colorModifier = 1 - 0.96 * step(0, sin(125.0 * (p.y)));
                }
				surfaceColor = float3(1.0 * colorModifier, 1.0 * colorModifier, 1.0 * colorModifier);

                if (elementSlab < frontElement) {
                    elementID = 3;
                    surfaceColor = float3(0.01, 0.01, 0.01);
                    return elementSlab;
                }

                return smin(element1, element2, 1.5);
                //return min(element1, element2);
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
				float touchDistance;
				while ((stepNumber == 0) || (travelDistance < maxDistance && distanceToSurface > touchDistance && stepNumber < maxSteps)) {
					stepNumber += 1;
					rayPosition = eyePosition + travelDistance * viewDirection;
					distanceToSurface = distanceEstimator(rayPosition);
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
