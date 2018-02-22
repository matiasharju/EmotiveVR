using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MemoryScript : MonoBehaviour
{
    public float memoryNumber;
    private Material targetMaterial;
    private ShaderParameters shaderParameters;

    public List<MemoryScript> activates;
    public List<MemoryScript> deactivates;
    private GameObject player;
    public bool expired = false;

    public ShaderParameters ShaderParameters
    {
        get { return shaderParameters; }
        set { shaderParameters = value; }
    }

    public Material TargetMaterial
    {
        get { return targetMaterial; }
        set { targetMaterial = value; }
    }

    void Awake()
    {
 
        player = GameObject.Find("ShaderPlane");
    }

    private void Start()
    {
        TargetMaterial = TargetMaterial ?? GetComponent<Material>();
        ShaderParameters = GetComponent<ShaderParameters>();
    }

    void Update()
    {
        if (player != null)
        {
            if (Vector3.Distance(player.transform.position, transform.position) < 0.6f)
            {
                Debug.Log("PORTALING");

                GameController.instance.TriggerMemory(this);
            }

        }
        else
        {
            player = GameObject.Find("ShaderPlane");
        }
    }

    public void Activate()
    {
        Debug.Log("Activating memory number");
        Debug.Log(name);
        Debug.Log(!expired);
        if (!expired) gameObject.SetActive(true);
        Debug.Log(gameObject.activeSelf);
    }

    public void Deactivate()
    {
        gameObject.SetActive(false);
    }


}
