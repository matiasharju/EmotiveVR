using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class Voice : Portal {

    public Vector3 EpiloguePosition = new Vector3(6, 12, 6);

    public Vector3 PoetPosition = new Vector3(6, 12, 18);
    public Vector3 PioneerPosition = new Vector3(18, 6, 24);
    public Vector3 MachinePosition = new Vector3(24, 18, 6);
    public Vector3 SkepticPosition = new Vector3(12, 24, 6);

	void Awake () {
        memories.Sort((p, q) => p.memoryNumber.CompareTo(q.memoryNumber));
    }

    public void ActivateNextMemory()
    {
        memories.FirstOrDefault(m => !m.expired).Activate();
    }

}
