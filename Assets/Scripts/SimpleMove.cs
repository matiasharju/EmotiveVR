using UnityEngine;

public class SimpleMove : MonoBehaviour
{
    [HideInInspector]
    public Transform rig;

    private void Update()
    {
        if (rig)
        {
            var x = Input.GetAxis("Horizontal") * Time.deltaTime * 3.0f;
            var z = Input.GetAxis("Vertical") * Time.deltaTime * 3.0f;

            float y = 0;
            if (Input.GetButton("Up"))
            {
                y = 1f * Time.deltaTime * 3.0f;
            }
            if (Input.GetButton("Down"))
            {
                y = -1f * Time.deltaTime * 3.0f;
            }
            rig.transform.Translate(x, y, z);
        }
    }

}
