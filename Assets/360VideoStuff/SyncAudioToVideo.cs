using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Video;

public class SyncAudioToVideo : MonoBehaviour {

private bool startTriggered = false;	// Booleans for playing the sound events only once
private bool beepTriggered = false;

public float VideoSoundBeginsAt = 0.00F;	// Sound events' starting times in seconds
public float BeepPlaysAt = 2.00F;

VideoPlayer videoPlayer;

    void Start()
    {
        videoPlayer = GetComponent<VideoPlayer> ();	
    }

	void Update () 
	{	
		if (videoPlayer.time >= (VideoSoundBeginsAt - 0.005) && videoPlayer.time < (VideoSoundBeginsAt + 0.02) && startTriggered == false)
		{
			AkSoundEngine.PostEvent("StartVideoSound", gameObject);	// Triggers the video sound event at defined time
			Debug.Log("<color=green>Start Video Sound at 00:00</color>" + " " + videoPlayer.time);
			startTriggered = true;
		}

		if (videoPlayer.time > (VideoSoundBeginsAt + 0.02))	
		{
			startTriggered = false;		// Resets the boolean
		}

		if (videoPlayer.time >= (BeepPlaysAt - 0.005) && videoPlayer.time < (BeepPlaysAt + 0.02) && beepTriggered == false)
		{
			AkSoundEngine.PostEvent("PlayBeep", gameObject);	// Triggers the beep at defined time
			Debug.Log("<color=blue>Play Beep at 2:00</color>" + " " + videoPlayer.time);
			beepTriggered = true;
		}

		if (videoPlayer.time > (BeepPlaysAt + 0.02))
		{
			beepTriggered = false;		// Resets the boolean
		}


	}

}

