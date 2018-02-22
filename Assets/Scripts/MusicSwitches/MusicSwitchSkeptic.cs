using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MusicSwitchSkeptic : MonoBehaviour {

	void Start () {
		AkSoundEngine.SetSwitch("MusicSwitch", "Skeptic", gameObject);		
	}
	
	void Update () {
		
	}
}
