// Normaalit kiiltoja yms varten.
float3 fastSurfaceNormalNearPoint(float3 p, float epsilon) {
    return normalize(float3(
            distanceEstimator(p + float3(epsilon, 0, 0), false),
            distanceEstimator(p + float3(0, epsilon, 0), false),
            distanceEstimator(p + float3(0, 0, epsilon), false)
    ));
}

float3 fastSurfaceNormalNearPoint(float3 p) {
    return fastSurfaceNormalNearPoint(p, 0.0001f);
}

float3 accurateSurfaceNormalNearPoint(float3 p, float epsilon) {
    return normalize(float3(
            distanceEstimator(p + float3(epsilon, 0, 0), false) - distanceEstimator(p - float3(epsilon, 0, 0), false),
            distanceEstimator(p + float3(0, epsilon, 0), false) - distanceEstimator(p - float3(0, epsilon, 0), false),
            distanceEstimator(p + float3(0, 0, epsilon), false) - distanceEstimator(p - float3(0, 0, epsilon), false)
    ));
}

float3 accurateSurfaceNormalNearPoint(float3 p) {
    return accurateSurfaceNormalNearPoint(p, 0.0001f);
}

float4 accurateSurfaceNormalPlusAcuteness(float3 p, float epsilon) {

    float location = distanceEstimator(p, false);
    float pointX1 = distanceEstimator(p + float3(epsilon, 0, 0), false);
    float pointX2 = distanceEstimator(p - float3(epsilon, 0, 0), false);
    float pointY1 = distanceEstimator(p + float3(0, epsilon, 0), false);
    float pointY2 = distanceEstimator(p - float3(0, epsilon, 0), false);
    float pointZ1 = distanceEstimator(p + float3(0, 0, epsilon), false);
    float pointZ2 = distanceEstimator(p - float3(0, 0, epsilon), false);

    float tangentX = dot(normalize(location - pointX1), normalize(location - pointX2));
    float tangentY = dot(normalize(location - pointY1), normalize(location - pointY2));
    float tangentZ = dot(normalize(location - pointZ1), normalize(location - pointZ2));

    float acuteness = max(tangentX, tangentY);
    acuteness = max(acuteness, tangentZ);

    float3 surfaceNormal = normalize(float3(
            pointX1 - pointX2,
            pointY1 - pointY2,
            pointZ1 - pointZ2
    ));

    return float4(surfaceNormal, acuteness);


}
