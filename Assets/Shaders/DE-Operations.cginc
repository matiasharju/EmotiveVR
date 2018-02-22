
    const float pi = 3.14159;
    // Rotations
    // Angle in radians
    float3x3 rotateXY(float angle) {
        return float3x3(
            cos(angle), sin(angle), 0,
            -sin(angle), cos(angle), 0,
            0, 0, 1);
    }

    float3x3 rotateXZ(float angle) {
        return float3x3(
            cos(angle), 0, sin(angle),
            0, 1, 0,
            -sin(angle), 0, cos(angle));
    }

    float3x3 rotateYZ(float angle) {
        return float3x3(
            1, 0, 0,
            0, cos(angle), sin(angle),
            0, -sin(angle), cos(angle));
    }

    // Boolean operations - Union, Subtraction, Intersection
    float opU(float d1, float d2) {
        return min(d1, d2);
    }

    float opS(float d1, float d2) {
        return max(-d1, d2);
    }

    float opI(float d1, float d2) {
        return max(d1, d2);
    }

    // Polynomial smooth minimum
    float smin( float a, float b, float smoothness) {
        float h = clamp(0.5 + 0.5 * (b - a) / smoothness, 0.0, 1.0);
        return lerp(b, a, h) - smoothness * h * (1.0 - h);
    }

    // Displacements
    float displace3dSinWaves( float3 p, float strenght) {
        strenght = 1 / strenght;
        return sin(strenght * p.x) * sin(strenght * p.y) * sin(strenght * p.z);
    }

    // random
    float random(float3 seed){
        return frac(sin(dot(seed.xyz ,float3(12.9898, 78.233, 43.2343))) * 43758.5453);
    }

    // Noise - Value Noise
    float4 valueNoise(float3 x) {
        float3 p = floor(x);
        float3 w = frac(x);
        float3 u = w * w * w * (w * (w * 6.0 - 15.0) + 10.0);
        float3 du = 30.0 * w * w * (w * (w - 2.0) + 1.0);

        float a = random( p+float3(0,0,0) );
        float b = random( p+float3(1,0,0) );
        float c = random( p+float3(0,1,0) );
        float d = random( p+float3(1,1,0) );
        float e = random( p+float3(0,0,1) );
        float f = random( p+float3(1,0,1) );
        float g = random( p+float3(0,1,1) );
        float h = random( p+float3(1,1,1) );

        float k0 =   a;
        float k1 =   b - a;
        float k2 =   c - a;
        float k3 =   e - a;
        float k4 =   a - b - c + d;
        float k5 =   a - c - e + g;
        float k6 =   a - b - e + f;
        float k7 = - a + b + c - d + e - f - g + h;

        return float4( -1.0 + 2.0 * (k0 + k1*u.x + k2*u.y + k3*u.z + k4*u.x*u.y + k5*u.y*u.z + k6*u.z*u.x + k7*u.x*u.y*u.z),
                              2.0 * du * float3( k1 + k4*u.y + k6*u.z + k7*u.y*u.z,
                                              k2 + k5*u.z + k4*u.x + k7*u.z*u.x,
                                              k3 + k6*u.x + k5*u.y + k7*u.x*u.y ) );
    }

    float4 fractionalBrownianMotion(float3 x, int octaves) {
        float f = 1.98;  // could be 2.0
        float s = 0.49;  // could be 0.5
        float a = 0.0;
        float b = 0.5;
        float3 d = float3(0, 0, 0);
        float3x3 m = float3x3(1.0, 0.0, 0.0,
                0.0, 1.0, 0.0,
                0.0, 0.0, 1.0);
        for( int i = 0; i < octaves; i++ ) {
            float4 n = valueNoise(x);
            a += b * n.x;          // accumulate values
            float temp1 = b * m;
            float temp2 = 0;
            d += temp1 * n.yzw;      // accumulate derivatives
            b *= s;
            x = f * m[2] * x;
            m = f * m[2][i] * m;
        }
        return float4( a, d );
    }

    /*const float2x2 m = float2x2(0.8,-0.6,0.6,0.8);

    float terrain( float2 p ) {
    float a = 0.0;
    float b = 1.0;
    float2  d = float2(0.0, 0.0);
    for( int i=0; i<15; i++ )
        {
            float3 n = valueNoise(p.xyy).xyz;
            d += n.yz;
            a += b*n.x/(1.0+dot(d,d));
            b *= 0.5;
            p = m*p*2.0;
        }
        return a;
    }*/
