using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Video;

public class FreudAVSync : MonoBehaviour {

private bool freudTriggered = false;	// Booleans for playing the sound events only once
private bool intermusicTriggered = false;

public float FreudAudioStarts = 0.00F;	// Sound events' starting times in seconds
public float InteractiveMusicStarts = 12.00F;

private GameObject staticAudioSource;

VideoPlayer videoPlayer;

    void Start()
    {
		staticAudioSource = GameObject.Find("StaticAudioSource");

        videoPlayer = GetComponent<VideoPlayer> ();	
		videoPlayer.Play();
    }

	void Update () 
	{	
		if (videoPlayer.time >= (FreudAudioStarts - 0.005) && videoPlayer.time < (FreudAudioStarts + 0.02) && freudTriggered == false)
		{
			AkSoundEngine.PostEvent("PlayFreudAudio", staticAudioSource.gameObject);
			Debug.Log("<color=green>Start Freud Audio at 00:00</color>" + " " + videoPlayer.time);
			freudTriggered = true;
		}

		if (videoPlayer.time > (FreudAudioStarts + 0.02))	
		{
			freudTriggered = false;		// Resets the boolean
		}

/* 
		if (videoPlayer.time >= (InteractiveMusicStarts - 0.005) && videoPlayer.time < (InteractiveMusicStarts + 0.02) && intermusicTriggered == false)
		{
			AkSoundEngine.PostEvent("Interactive_Music_2", Sphere.gameObject);
			Debug.Log("<color=blue>Start Interactive Music at 12:00</color>" + " " + videoPlayer.time);
			intermusicTriggered = true;
		}

		if (videoPlayer.time > (InteractiveMusicStarts + 0.02))
		{
			intermusicTriggered = false;		// Resets the boolean
		}
*/

	}

}

