using UnityEngine;

public class sphereFollowCamera : MonoBehaviour
{
    public Camera cam;

	private void Start ()
    {
        //cam = Camera.main;
    }

    public void centerSphere(int orientation)
    {
        Vector3 a = transform.eulerAngles;
        // Center view to camera
        a.y = cam.transform.eulerAngles.y - 90;
        // Add orientation condition
        a.y += orientation;
        transform.eulerAngles = a;
    }

	private void Update ()
    {
        transform.position = cam.transform.position;
    }
}
