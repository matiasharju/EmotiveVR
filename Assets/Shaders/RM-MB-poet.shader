// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/RM-MB-Poet"
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
		 _derivative ("Fractal Derivative", range (0.0, 4.0)) = 0.75 // usually 1.0 in mandelboxes
		 _mandelbulbPower ("Mandelbulb Power", range (0.0, 16.0)) = 5.0
		 _overShoot ("DE Overshoot", range (0.0, 5.0)) = 1.0

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
			float _derivative = 0.75;
			float _overShoot = 1.0;
			float _mandelbulbPower = 5.0;
			float4 trap;
			float mandelbulb(float3 p, int iterations) {
				float3 w = p / 2.5;
				float m = dot(w,w);

				trap = float4(abs(w),m);
				float dz = _derivative;
				int power = _mandelbulbPower;

				for( int i=0; i < iterations; i++ )
				{
					// to polar coordinates
					float m2 = m*m;
					float m4 = m2*m2;
					dz = power*sqrt(m4*m2*m)*dz + 1.0;

					float x = w.x; float x2 = x*x; float x4 = x2*x2;
					float y = w.y; float y2 = y*y; float y4 = y2*y2;
					float z = w.z; float z2 = z*z; float z4 = z2*z2;
					// scale and rotate
					float k3 = x2 + z2;
					float k2 = 1/sqrt( k3*k3*k3*k3*k3*k3 ); // alkuperäisessä on 7 k3:sta
					float k1 = x4 + y4 + z4 - 6.0*y2*z2 - 6.0*x2*y2 + 2.0*z2*x2;
					float k4 = x2 - y2 + z2;
					// back to cartesian coordinates
					w.x = p.x +  64.0*x*y*z*(x2-z2)*k4*(x4-6.0*x2*z2+z4)*k1*k2;
					w.y = p.y + -16.0*y2*k3*k4*k4 + k1*k1;
					w.z = p.z +  -8.0*y*k4*(x4*x4 - 28.0*x4*x2*z2 + 70.0*x4*z4 - 28.0*x2*z2*z4 + z4*z4)*k1*k2;

					// orbit trap
					trap = min( trap, float4(abs(w),m) );

					m = dot(w,w);
					if( m > 4.0 )
					break;
				}
				trap.w = m;

				return 0.05*log(m)*sqrt(m)/dz;
			}

			// DISTANCE ESTIMATOR
			float distanceEstimator(float3 rayPosition) {
				float overShoot = _overShoot; // default 1.0 - pienempi luku tekee hurjan tunneliefektin
				float3 p = mul( (rayPosition - _objectOffset - _worldOffset), _worldMatrix); //
				float zoom = 15;
				p /= zoom;
                float element1 = 10000; // big number means nothing
				//float element2 = mandelboxDE(p, 3) * zoom * overShoot;
				float element2 = mandelbulb(p, _iterations) * zoom * overShoot;
                float frontElement = element1;

                elementID = 1;
				float colorModifier = 1 - smoothstep(-0, 0, sin(20.0 * (p.y)) + sin(20.0 * p.x) + sin(20.0 * p.z)); //pallokuosi
				surfaceColor = _color2;
				//surfaceColor *= pow(trap, 0.2);

                if (element2 < element1) {
                    frontElement = element2;
                    elementID = 2;
                    float h = sin(_Time.y/10) / 2;

					//colorModifier = 1 - 0.96 * step(0.02, trap.y) - sin(250.0 * (p.y * trap.w));
					surfaceColor.r += sin(p.y * trap.w);
					surfaceColor.g += sin(p.y * trap.g);
					surfaceColor.b *= 2 * step(0.06, trap.b);
					surfaceColor.b -= step(0.7, surfaceColor.g);
					surfaceColor += 1 - 0.96 * step(0.02, trap.y);
                }

                return smin(element1, element2, 1.5);
                //return min(element1, element2);
			}
			//#include "DE-SurfaceNormals.cginc"
            // Kiiltoja yms varten. Ei käytössä nyt.

			float3 accurateSurfaceNormalNearPoint(float3 p, float epsilon) {
				return normalize(float3(
						distanceEstimator(p + float3(epsilon, 0, 0)) - distanceEstimator(p - float3(epsilon, 0, 0)),
						distanceEstimator(p + float3(0, epsilon, 0)) - distanceEstimator(p - float3(0, epsilon, 0)),
						distanceEstimator(p + float3(0, 0, epsilon)) - distanceEstimator(p - float3(0, 0, epsilon))
				));
			}



			fixed4 frag (v2f input) : SV_Target {

				// Raymarch parameters
				float maxSteps = 120;
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
						travelDistance += travelMultiplier * distanceToSurface;
						touchDistance = touchDistanceMultiplier * travelDistance;
				}

				bool didHitSurface = distanceToSurface <= touchDistance * 10;

				float brightness = stepNumber/maxSteps;
				if (!didHitSurface) {
					brightness = 1 - brightness;
					brightness = pow(brightness, 0.4);
					return float4(pow(brightness, 0.5), pow(brightness, 1.2), pow(brightness, 1.1), 1);
				}
				brightness = log(stepNumber) / log(maxSteps);
				brightness = pow(1-brightness, 1);
				brightness = pow(brightness, exp(-(brightness*2)));

                // Element colors
                surfaceColor *= brightness;
				float specularThreshold = 0.995;
				fixed3 fakeSpecular = max(smoothstep(specularThreshold, 1, surfaceColor.r), max(smoothstep(specularThreshold, 1, surfaceColor.g), smoothstep(specularThreshold, 1, surfaceColor.b)));
                return fixed4(surfaceColor + fakeSpecular, 1.0);
			}
			ENDCG
		}
	}
}
