using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShaderParameters : MonoBehaviour {

    public Vector4 worldOffset = new Vector4(0, 0, 0, 0); // 2017-12-17
    //public Matrix4x4 worldRotation = new Matrix4x4(); // 2017-12-17

    // For Mandelbox (and why not others as well)
    public float foldValue = 0.0f;
    public float foldLimit = 0.0f;
    public float smallRadius = 0.5f;
    public float bigRadius = 1.0f;
    [Range(1,30)]
    public int iterations = 6;

    // Generic parameters
    public float knob1 = 0.0f;
    public float knob2 = 0.0f;
    public float knob3 = 0.0f;
    public float knob4 = 0.0f;
    public float knob5 = 0.0f;
    public float knob6 = 0.0f;
    public float knob7 = 0.0f;
    public float knob8 = 0.0f;

    // Color parameters
    public Color color1 = new Color(1, 0, 0, 1);
    public Color color2 = new Color(0, 1, 0, 1);
    public Color color3 = new Color(0, 0, 1, 1);
    public Vector4 sunLight = new Vector4(1, 1, 1, 1); // 2017-12-17

    // For KIFS
    public float foldRotateXY = 0.0f;
    public float foldRotateXZ = 0.0f;
    public float foldRotateYZ = 0.0f;

    
    public override string ToString()
    {
		return "World offset: " + worldOffset.ToString() + " | " +
		"Fold value: " + foldValue.ToString() + " | " +
        "Fold limit: " + foldLimit.ToString() + " | " +
        "Small radius " + smallRadius.ToString() + " | " +
        "Big radius: " + bigRadius.ToString() + " | " +
        "Iterations: " + iterations.ToString() + " | " +
        "Knob1: " + knob1.ToString() + " | " +
        "Knob2: " + knob2.ToString() + " | " +
        "Knob3: " + knob3.ToString() + " | " +
        "Knob4: " + knob4.ToString() + " | " +
        "Knob5: " + knob5.ToString() + " | " +
        "Knob6: " + knob6.ToString() + " | " +
        "Knob7: " + knob7.ToString() + " | " +
        "Knob8: " + knob8.ToString() + " | " +
        "Color1 " + color1.ToString() + " | " +
        "Color2: " + color2.ToString() + " | " +
        "Color3: " + color3.ToString() + " | " +
        "Sunlight: " + sunLight.ToString() + " | " +
        "foldRotateXY: " + foldRotateXY.ToString() + " | " +
        "foldRotateXZ: " + foldRotateXZ.ToString() + " | " +
        "foldRotateXZ: " + foldRotateYZ.ToString() + " | ";
    }
    
}
