using System.Collections;
using System.Collections.Generic;
using System;
using UnityEngine;

public class AudioRTPCMemory : MonoBehaviour {

public float centralFreq = 400;
public float memoryBaseFreq;
double angle;

	void Start () {
	}
	
	void Update () {

		memoryBaseFreq = centralFreq + Convert.ToSingle(Math.Sin(angle)*100);
		angle = angle + 0.05;
 		
		AkSoundEngine.SetRTPCValue("MemoryBaseFreq", memoryBaseFreq);

	}
}
