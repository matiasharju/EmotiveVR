//
//  Created by Valtteri Bade on 2017-12-01.


// Vignetting
float vignette(float2 coords, float power) {
    return pow(1.0 - length(coords), power);
}

//Threshold
fixed4 threshold(fixed4 color, float threshold) {
    return round(clamp(color/threshold, 0.0, 1.0));
}

//Posterize


