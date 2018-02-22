using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Portal : MonoBehaviour
{
    public Material material;
    public List<MemoryScript> memories;
    public List<DistanceTrigger> distanceTriggers;

	private ShaderParameters shaderParameters;

	public ShaderParameters ShaderParameters
	{
		get { return shaderParameters; }
		set { shaderParameters = value; }
	}

    private void Start()
    {
        foreach (MemoryScript memory in memories)
        {
            memory.TargetMaterial = material;
            memory.GetComponent<MeshRenderer>().material = material;
			shaderParameters = gameObject.GetComponent<ShaderParameters> ();
        }
    }

    public void UpdatePosition(Vector3 position)
    {
        gameObject.transform.position = position;
    }

    public void ActivateDistanceTriggers()
    {
        if (distanceTriggers != null)
        {
			distanceTriggers.ForEach(d => d.Activate());
        }
 
    }
    public void DeactivateDistanceTriggers()
    {
        if (distanceTriggers != null)
        {
			distanceTriggers.ForEach(d => d.Deactivate());
        }   
    }
}
