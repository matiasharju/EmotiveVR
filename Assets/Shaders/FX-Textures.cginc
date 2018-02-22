// Author @patriciogv - 2015
// http://patriciogonzalezvivo.com

float rand (float2 _st) {
    return frac(sin(dot(_st.xy,
                         float2(12.9898,78.233)))*
        43758.5453123);
}

// Based on Morgan McGuire @morgan3d
// https://www.shadertoy.com/view/4dS3Wd
float noise (float2 _st) {
    float2 i = floor(_st);
    float2 f = frac(_st);

    // Four corners in 2D of a tile
    float a = rand(i);
    float b = rand(i + float2(1.0, 0.0));
    float c = rand(i + float2(0.0, 1.0));
    float d = rand(i + float2(1.0, 1.0));

    float2 u = f * f * (3.0 - 2.0 * f);

    return lerp(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

#define NUM_OCTAVES 5

float fbm ( float2 _st) {
    float v = 0.0;
    float a = 0.5;
    float2 shift = float2(100.0, 100.0);
    // Rotate to reduce axial bias
    float2x2 rot = float2x2(cos(0.5), sin(0.5),
                    -sin(0.5), cos(0.50));
    for (int i = 0; i < NUM_OCTAVES; ++i) {
        v += a * noise(_st);
        _st = mul(rot, _st) * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

float4 swirlingClouds(float2 uv) {
    float2 st = uv*5;
     //st += st * abs(sin(_Time*0.1)*3.0);
    float3 color = float3(0.0, 0, 0);

    float2 q = float2(0, 0);
    q.x = fbm( st + 0.00*_Time);
    q.y = fbm( st + float2(1.0, 1));

    float2 r = float2(0.0, 0.0);
    float x = st + 1.0*q + float2(1.7,9.2) + 2.5*_Time;
    float y = st + 1.0*q + float2(8.3,2.8) + 4.6*_Time;
    r.x = fbm(x + fbm(x + fbm ( x)));
    r.y = fbm(y + fbm(y + fbm( y)));

    float f = fbm( (st + r) + fbm((st + r) + fbm(st+r)));

    color = lerp(float3(0.101961,0.619608,0.666667),
                float3(0.666667,0.666667,0.498039),
                clamp((f*f)*4.0,0.0,1.0));

    color = lerp(color,
                float3(0,0,0.164706),
                clamp(length(q),0.0,1.0));

    color = lerp(color,
                float3(0.666667,1,1),
                clamp(length(r.x),0.0,1.0));

    return float4((f*f*f+.6*f*f+.5*f)*color,1.);
}
