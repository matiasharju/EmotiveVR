using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShaderEntity : MonoBehaviour {

    public string name;

    public int shape;
    public Vector4 color;

    [HideInInspector] public Vector3 position;
    [HideInInspector] public Quaternion rotation;
}
