    // Geometric primitives
    float sphere(float3 p, float radius) {
        return length(p) - radius;
    }

    float sphere(float3 p, float2 radius) {
        return sphere(p, radius.x);
    }

    float ellipsoid(float3 p, float3 r) {
        return (length( p/r ) - 1.0) * min(min(r.x, r.y), r.z);
    }

    float box(float3 p, float3 dimensions) {
        return length(max(abs(p) - dimensions, 0.0));
    }

    float box(float3 p, float2 dimensions) {
        return box(p, dimensions.xxy);
    }

    float box(float3 p, float dimensions) {
        return box(p, dimensions.xxx);
    }

    float cube(float3 p, float dimensions) {
        return box(p, dimensions.xxx);
    }

    float boxRounded(float3 p, float3 dimensions, float radius) {
        return length(max(abs(p) - dimensions, 0.0)) - radius;
    }

    float torus(float3 p, float2 t) {
        float2 q = float2(length(p.xz)-t.x, p.y);
        return length(q)-t.y;
    }

    float cylinder(float3 p, float3 c) {
        return length(p.xz - c.xy) - c.z;
    }

    float cone(float3 p, float2 c) {
        float q = length(p.xy);
        return dot(c, float2(q, p.z));
    }

    float plane(float3 p, float4 n) {
        n = normalize(n);
        return dot(p, n.xyz) + n.w;
    }

    float hexPrism(float3 p, float2 h) {
        float3 q = abs(p);
        return max(q.z - h.y, max((q.x * 0.866025 + q.y * 0.5), q.y)-h.x);
    }

    float capsule(float3 p, float3 a, float3 b, float r) {
        float3 pa = p - a, ba = b - a;
        float h = clamp(dot(pa, ba)/dot(ba, ba), 0.0, 0.1);
        return length(pa - ba * h) - r;
    }
