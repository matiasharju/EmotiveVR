using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class GameController : MonoBehaviour
{
    public static GameController instance;

    public bool debug = false;

    public ShaderManager shaderManager;

    public Voice poet;
    public Voice pioneer;
    public Voice machine;
    public Voice skeptic;

    public Portal limbo;
    public Portal prologue;
    public Portal epilogue;

    public Portal startingArea;

    private Portal currentPortal;

    private List<Voice> voices = new List<Voice>();
    private List<Portal> portals = new List<Portal>();

    private List<DistanceTrigger> distanceTriggers = new List<DistanceTrigger>();

    void Awake()
    {
        if (instance == null)
        {
            instance = this;
        }
        else if (instance != this)
        {
            Destroy(gameObject);
        }

        currentPortal = startingArea;

    }

    private void Start()
    {
        portals.Add(prologue);
        portals.Add(epilogue);
        portals.Add(limbo);

        voices.Add(poet);
        voices.Add(pioneer);
        voices.Add(machine);
        voices.Add(skeptic);

        voices.ForEach(v => portals.Add(v));

        UpdateDistanceTriggers(currentPortal);

        AkSoundEngine.SetRTPCValue("MemoryNumber", 0);

    }

    private void Update()
    {
        
    }

    public void TriggerMemory(MemoryScript memory)
    {

        memory.expired = true;

        // Clear trail renderers
        GameObject[] trailRenderers = GameObject.FindGameObjectsWithTag("LineRenderer");
        foreach (GameObject obj in trailRenderers)
        {
            if (obj.GetComponent<TrailRenderer>())
            {
                obj.GetComponent<TrailRenderer>().Clear();
            }
        }

        // Update current portal

        currentPortal = portals.Find(p => p.memories.Contains(memory)) ?? currentPortal;

		Debug.Log ("Current portal:");
		Debug.Log (currentPortal);

        // Update shader and shader parameters
        GameObject.Find("Quad").GetComponent<MeshRenderer>().material = memory.TargetMaterial;
        shaderManager.SetShaderMaterial();
		shaderManager.UpdateShaderParameters(memory.ShaderParameters ?? currentPortal.ShaderParameters);

        // Update active distance triggers
        UpdateDistanceTriggers(currentPortal);

        // Update memory positions and activation states
        Voice voice = voices.Find(v => v.Equals(currentPortal));
		Debug.Log ("Current voice:");
		Debug.Log (voice);
        if (voice != null)
        {
            poet.UpdatePosition(voice.PoetPosition);
            pioneer.UpdatePosition(voice.PioneerPosition);
            machine.UpdatePosition(voice.MachinePosition);
            skeptic.UpdatePosition(voice.SkepticPosition);

            voices.FindAll(v => !v.Equals(voice)).ForEach(v => v.ActivateNextMemory());
        }
        foreach (MemoryScript activated in memory.activates) activated.Activate();
        foreach (MemoryScript deactivated in memory.deactivates) deactivated.Deactivate();

        // Play memory sounds
        AkSoundEngine.SetRTPCValue("MemoryNumber", memory.memoryNumber);
        AkSoundEngine.PostEvent("Memory", memory.gameObject);

        memory.gameObject.SetActive(false);

    }

    private void UpdateDistanceTriggers(Portal portal)
    {
        this.distanceTriggers.ForEach(d => d.Reset());
        this.distanceTriggers.Clear();
        portals.FindAll(p => !p.Equals(portal)).ForEach(p => p.DeactivateDistanceTriggers());
        portal.ActivateDistanceTriggers();
        portal.distanceTriggers.ForEach(d => this.distanceTriggers.Add(d));
    }

}
