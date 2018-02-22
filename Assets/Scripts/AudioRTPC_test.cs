using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AudioRTPC_test : MonoBehaviour {

//public float baseFreq = 25;	// Binded to built-in Object-to-listener Angle parameter
public float osc1transp = 60;
public float osc1PWM = 55;
public float osc2transp = -300;
public float osc2PWM = 45;

	void Start () {
		
	}
	
	void Update () {
		
//		AkSoundEngine.SetRTPCValue("BaseFreq", baseFreq);
		AkSoundEngine.SetRTPCValue("Osc1Transp", osc1transp);
		AkSoundEngine.SetRTPCValue("Osc1PWM", osc1PWM);
		AkSoundEngine.SetRTPCValue("Osc2Transp", osc1transp);
		AkSoundEngine.SetRTPCValue("Osc2PWM", osc2PWM);

	}
}
