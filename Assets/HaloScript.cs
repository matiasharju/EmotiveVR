using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class HaloScript : MonoBehaviour
{
    public Transform player;

    // Use this for initialization
    void Awake()
    {
        GameObject obj = GameObject.Find("ShaderPlane");
        if (obj != null) player = obj.transform;
    }

    // Update is called once per frame
    void Update()
    {
        if (player != null)
        {
            transform.rotation = Quaternion.LookRotation(-(player.position - transform.position).normalized);
            transform.localPosition = -(player.position - transform.position).normalized * 2;
        } else
        {
            GameObject obj = GameObject.Find("ShaderPlane");
            if (obj != null) player = obj.transform;
        }
    }
}
