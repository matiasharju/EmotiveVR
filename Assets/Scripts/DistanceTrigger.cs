using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DistanceTrigger : MonoBehaviour {

    public float triggerDistance;
    private ShaderParameters start;
    private ShaderParameters current;
    private ShaderParameters target;
    public float transitionTime = 1.0f;
	public GameObject soundSource;
    public GameObject soundSource1;
    public GameObject soundSource2;
    public GameObject soundSource3;
    public bool active = false;


    private GameObject player;

    private ShaderManager shaderManager;

    private float timer;
    private bool triggered = false;
    private bool expired = false;

    void Awake()
    {
        player = GameObject.Find("ShaderPlane");
        target = gameObject.GetComponent<ShaderParameters>();
        current = gameObject.AddComponent<ShaderParameters>() as ShaderParameters;
    }

    private void Start()
    {
        shaderManager = GameController.instance.shaderManager;
    }

    private void OnValidate()
    {
        transitionTime = Mathf.Clamp(transitionTime, 1, int.MaxValue);
        triggerDistance = Mathf.Clamp(triggerDistance, 0, int.MaxValue);
    }

    public void Reset()
    {
        active = false;
        triggered = false;
        expired = false;
        timer = 0;
    }

	public void Deactivate() {
		this.active = false;
		this.gameObject.SetActive(false);
	
	}
	public void Activate() {
		this.active = true;
		this.gameObject.SetActive(true);
	}


    public double DistanceFromPlayer()
    {
        return Vector3.Distance(player.transform.position, transform.position);
    }

    void Update()
    {
        if (DistanceFromPlayer() <= triggerDistance && !triggered && active)
        {
            triggered = true;
			timer = 0;
            Debug.Log("Starting shader transition");
			start = shaderManager.shaderParameters;
            Debug.Log("Start parameters:");
            Debug.Log(start);
            Debug.Log("Target parameters:");
            Debug.Log(target);
			shaderManager.SetShaderMaterial ();

			if (soundSource != null) {
				AkSoundEngine.PostEvent("Movement", soundSource);
                AkSoundEngine.PostEvent("Movement", soundSource1);
                AkSoundEngine.PostEvent("Movement", soundSource2);
                AkSoundEngine.PostEvent("Movement", soundSource3);
            }
        }

        if (triggered && !expired && start != null && target != null && active)
        {

            timer += Time.deltaTime;
            float ip = Mathf.Clamp01(timer / transitionTime);

            current.worldOffset =        Vector4.Lerp(start.worldOffset,   target.worldOffset,   ip);

            current.foldValue =        Mathf.Lerp(start.foldValue,   target.foldValue,   ip);
            current.foldLimit =        Mathf.Lerp(start.foldLimit,   target.foldLimit,   ip);
            current.smallRadius =      Mathf.Lerp(start.smallRadius, target.smallRadius, ip);
            current.bigRadius =        Mathf.Lerp(start.bigRadius,   target.bigRadius,   ip);
            current.iterations = (int) Mathf.Lerp(start.iterations,  target.iterations,  ip);

            current.knob1 = Mathf.Lerp(start.knob1, target.knob1, ip);
            current.knob2 = Mathf.Lerp(start.knob2, target.knob2, ip);
            current.knob3 = Mathf.Lerp(start.knob3, target.knob3, ip);
            current.knob4 = Mathf.Lerp(start.knob4, target.knob4, ip);
            current.knob5 = Mathf.Lerp(start.knob5, target.knob5, ip);
            current.knob6 = Mathf.Lerp(start.knob6, target.knob6, ip);
            current.knob7 = Mathf.Lerp(start.knob7, target.knob7, ip);
            current.knob8 = Mathf.Lerp(start.knob8, target.knob8, ip);

            current.color1 = Color.Lerp(start.color1, target.color1, ip);
            current.color2 = Color.Lerp(start.color2, target.color2, ip);
            current.color3 = Color.Lerp(start.color3, target.color3, ip);

            current.foldRotateXY = Mathf.Lerp(start.foldRotateXY, target.foldRotateXY, ip);
            current.foldRotateXZ = Mathf.Lerp(start.foldRotateXZ, target.foldRotateXZ, ip);
            current.foldRotateYZ = Mathf.Lerp(start.foldRotateYZ, target.foldRotateYZ, ip);
         
            shaderManager.UpdateShaderParameters(current);


            if (timer > transitionTime)
            {
				expired = true;
                Debug.Log("Finished shader transition; final parameters:");
                Debug.Log(current);
				Debug.Log (shaderManager.shaderParameters);
            }
            

        }
    }

  
}
