using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MusicSwitchMachine : MonoBehaviour {

	void Start () {
		AkSoundEngine.SetSwitch("MusicSwitch", "Machine", gameObject);		
	}
	
	void Update () {
		
	}
}
