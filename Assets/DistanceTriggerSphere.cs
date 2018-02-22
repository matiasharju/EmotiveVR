using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DistanceTriggerSphere : MonoBehaviour {
    void Start()
    {
        if (!GameController.instance.debug)
        {
            gameObject.SetActive(false);
        }
    }
}
