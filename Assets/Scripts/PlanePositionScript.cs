using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using VRTK;

public class PlanePositionScript : MonoBehaviour
{
    public Vector3 offset;
    
    public void UpdateTarget(Transform target, bool isSimulator)
    {
        transform.parent = target;
        //transform.rotation = target.rotation;
        transform.localPosition = offset;
    }
}
