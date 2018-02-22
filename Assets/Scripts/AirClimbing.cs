using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.XR;

public class AirClimbing : MonoBehaviour {

    XRNode rightHand;
    XRNode leftHand;

	// Use this for initialization
	void Start () {
        rightHand = XRNode.RightHand;
        leftHand = XRNode.LeftHand;
    }
	
	// Update is called once per frame
	void Update () {

	}
}
