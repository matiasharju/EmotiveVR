using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.XR;

public class ShaderManager : MonoBehaviour {

    public float globalTime;
    public float globalSpeed;
    Material shaderMaterial;

    // VR Gadgets in space
    public XRNode rightHand;
    public XRNode leftHand;

    // Raymarcher Parameters
    public float maxSteps = 90;
    public float maxDistance = 200;
    public float travelMultiplier = 1;
    public float touchDistanceMultiplier = 0.001f;


    // World Offset
	public Vector4 worldOffset;

    // public Quaternion worldRotation = Quaternion.identity; // 2017-12-17

    // For Mandelbox (and why not others as well)
	public float foldValue;
	public float foldLimit;
	public float smallRadius;
	public float bigRadius;
	[Range(1,30)]
	public int iterations;

    // Generic parameters
    public float knob1;
    public float knob2;
    public float knob3;
    public float knob4;
    public float knob5;
    public float knob6;
    public float knob7;
    public float knob8;

    // Color parameters
    public Color color1;
    public Color color2;
    public Color color3;
    public Vector4 sunLight;

    // For KIFS
    public float foldRotateXY;
    public float foldRotateXZ;
    public float foldRotateYZ;

	public ShaderParameters shaderParameters;

    List<ShaderEntity> shaderEntities = new List<ShaderEntity>();

    void Start()
    {
        globalTime = 0.0f;
        globalSpeed = 0.1f;
        shaderMaterial = GameObject.Find("Quad").GetComponent<Renderer>().material;

        AddControllers();
		rightHand = XRNode.RightHand;
		leftHand = XRNode.LeftHand;

        this.shaderParameters = gameObject.GetComponent<ShaderParameters>();
		UpdateShaderParameters (this.shaderParameters);

    }

    void Update()
    {
        globalTime += Time.deltaTime * globalSpeed;
        shaderMaterial.SetFloat("_globalTime", globalTime);
		shaderMaterial.SetVector("_worldOffset", this.worldOffset); // 2017-12-17

        // Hand parameters
        UpdateHands();

        // Mandelbox
		shaderMaterial.SetFloat("_foldValue", this.foldValue);
		shaderMaterial.SetFloat("_foldLimit", this.foldLimit);
		shaderMaterial.SetFloat("_smallRadius", this.smallRadius);
		shaderMaterial.SetFloat("_bigRadius", this.bigRadius);
		shaderMaterial.SetInt("_iterations", this.iterations);

        // Generic parameters
		shaderMaterial.SetFloat("_knob1", this.knob1);
        shaderMaterial.SetFloat("_knob2", this.knob2);
        shaderMaterial.SetFloat("_knob3", this.knob3);
        shaderMaterial.SetFloat("_knob4", this.knob4);
        shaderMaterial.SetFloat("_knob5", this.knob5);
        shaderMaterial.SetFloat("_knob6", this.knob6);
        shaderMaterial.SetFloat("_knob7", this.knob7);
        shaderMaterial.SetFloat("_knob8", this.knob8);

        // Color parameters
		shaderMaterial.SetColor("_color1", this.color1);
		shaderMaterial.SetColor("_color2", this.color2);
		shaderMaterial.SetColor("_color3", this.color3);
		shaderMaterial.SetVector("_sunLight", this.sunLight); // 2017-12-17

        // KIFS Rotations
		shaderMaterial.SetFloat("_foldRotateXY", this.foldRotateXY);
		shaderMaterial.SetFloat("_foldRotateXZ", this.foldRotateXZ);
		shaderMaterial.SetFloat("_foldRotateYZ", this.foldRotateYZ);
    }

	public void SetShaderMaterial() {
		shaderMaterial = GameObject.Find("Quad").GetComponent<MeshRenderer>().material;
		shaderMaterial.SetVector("_worldOffset", this.worldOffset);
		Debug.Log ("Material & world offset:");
		Debug.Log (shaderMaterial);
		Debug.Log (this.worldOffset);
    }

    public void UpdateShaderParameters(ShaderParameters parameters)
    {
        if (parameters != null )
        {
			Debug.Log ("Updating shader parameters");
			Debug.Log (parameters);

	        this.shaderParameters = parameters;
			this.worldOffset = parameters.worldOffset;
			this.foldValue = parameters.foldValue;
		
            this.foldLimit = parameters.foldLimit;
            this.smallRadius = parameters.smallRadius;
            this.bigRadius = parameters.bigRadius;
            this.iterations = parameters.iterations;

            this.knob1 = parameters.knob1;
            this.knob2 = parameters.knob2;
            this.knob3 = parameters.knob3;
            this.knob4 = parameters.knob4;
            this.knob5 = parameters.knob5;
            this.knob6 = parameters.knob6;
            this.knob7 = parameters.knob7;
            this.knob8 = parameters.knob8;
		    
            this.color1 = parameters.color1;
            this.color2 = parameters.color2;
            this.color3 = parameters.color3;
		    
            this.foldRotateXY = parameters.foldRotateXY;
            this.foldRotateXZ = parameters.foldRotateXZ;
            this.foldRotateYZ = parameters.foldRotateYZ;
        }
    }

    private void UpdateHands()
    {
        foreach (ShaderEntity entity in shaderEntities)
        {
            if (entity.name == "LeftController") {
                entity.position = InputTracking.GetLocalPosition(leftHand);
                entity.rotation = InputTracking.GetLocalRotation(leftHand);
				shaderMaterial.SetVector("_leftHandPosition", entity.position);
            } else if (entity.name == "RightController") {
                entity.position = InputTracking.GetLocalPosition(rightHand);
                entity.rotation = InputTracking.GetLocalRotation(rightHand);
				shaderMaterial.SetVector("_rightHandPosition", entity.position);
            }
        }
    }

    public void AddEntities(List<ShaderEntity> entities) {
        foreach (ShaderEntity entity in entities)
            shaderEntities.Add(entity);
    }

    public void AddControllers() {
        ShaderEntity left = new ShaderEntity();
        left.name = "LeftController";
        left.shape = 0;
        left.color = new Vector4();
        left.position = InputTracking.GetLocalPosition(leftHand);
        left.rotation = InputTracking.GetLocalRotation(leftHand);
        shaderEntities.Add(left);
        Debug.Log("Added hands");
        ShaderEntity right = new ShaderEntity();
        right.name = "RightController";
        right.shape = 0;
        right.color = new Vector4();
        right.position = InputTracking.GetLocalPosition(rightHand);
        right.rotation = InputTracking.GetLocalRotation(rightHand);
        shaderEntities.Add(right);
    }


     
}
