using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using VRTK;
using System;

public class RigSetupScript : MonoBehaviour
{

    private bool init = false;

    [HideInInspector] public bool isSimulator = false;

    ShaderManager shaderManager;

    void Start() {
//        shaderManager = GameObject.Find("ShaderPlane").GetComponent<ShaderManager>();
    }

    void Update()
    {
        if (!init) GetDevice();
    }

    void GetDevice()
    {
        string deviceName;
        try
        {
            deviceName = VRTK_SDKManager.instance.loadedSetup.systemSDKInfo.description.vrDeviceName;
        }
        catch (Exception ex)
        {
            Debug.Log("Could not find VR device:" + ex.Message);
            return;
        }
        Debug.Log(deviceName);
        if (deviceName == "None")
        {
            SetupSimulator();
        }
        else if (deviceName == "OpenVR")
        {
            SetupOpenVR();
        }
        else
        {
            Debug.Log("Unknown device name: " + deviceName);
        }
    }

    void SetupSimulator()
    {
        Debug.Log("Using simulator");
//        GameObject.Find("ShaderPlane").GetComponent<PlanePositionScript>().UpdateTarget(GameObject.Find("Neck/Camera").transform, true);
        GetComponent<SimpleMove>().rig = GameObject.Find("VRSimulatorCameraRig").transform;
        Debug.Log("Initialized successfully");
        init = true;
        isSimulator = true;
    }

    void SetupOpenVR()
    {
        Debug.Log("Using SteamVR");
//        GameObject.Find("ShaderPlane").GetComponent<PlanePositionScript>().UpdateTarget(GameObject.Find("Camera (eye)").transform, false);
        Debug.Log("Initialized successfully");
        init = true;
        isSimulator = false;
    }
    
}
