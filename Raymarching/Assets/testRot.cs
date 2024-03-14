using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class testRot : MonoBehaviour
{
    public Transform Sphere1;
    public Transform Sphere2;
    public Transform Sphere3;
    public Transform Sphere4;

    public float RotationAngl;
    public float Radius;
    public int PositionAngle;
    public float ArcDistn;
    public float AngleTest;
    
    public float range;       
   
    GameObject[,] spheres; 
    // Start is called before the first frame update
    void Start()
    {
        spheres = new GameObject[8, 3];
        RotationAngl = 2 * Mathf.PI / 8f;
        ArcDistn = Radius * RotationAngl;

        for (int i = 0; i < 8; i++)
        {
            float RotationAngles = 2 * Mathf.PI / 8f * i;
            Vector3 positionOrig = transform.position + new Vector3(Mathf.Cos(RotationAngles), 0, Mathf.Sin(RotationAngles)) * Radius;
            GameObject sphereTem = Instantiate(Sphere1.gameObject, positionOrig, Quaternion.identity);

            float dispersionAngle = RotationAngl / 3f;
            float coss = Mathf.Cos(dispersionAngle);
            float sinss = Mathf.Sin(dispersionAngle);
            Vector2 rotation = new Vector2(coss, sinss);

            Vector3 dir = (positionOrig - transform.position).normalized;
            float newX = dir.x * rotation.y - dir.z * rotation.x;
            float newY = dir.x * rotation.x + dir.z * rotation.y;

            float distArc = ArcDistn / 3f;
            Vector3 newPosLeft = new Vector3(newX, 0, newY).normalized;

            Vector3 positionLeft = positionOrig + newPosLeft * distArc;
            Vector3 positionRight= positionOrig + newPosLeft * -distArc;

            GameObject sphereTem2 = Instantiate(Sphere1.gameObject, positionLeft, Quaternion.identity);
            GameObject sphereTem3 = Instantiate(Sphere1.gameObject, positionRight, Quaternion.identity);

            spheres[i, 0] = sphereTem;
            spheres[i, 1] = sphereTem2;
            spheres[i, 2] = sphereTem3;
        }
    }
    private void OnDrawGizmos()
    {
        Gizmos.color = Color.green;
        Gizmos.DrawRay(transform.position, new Vector3(1,0,0) * range);
        Gizmos.DrawRay(transform.position, new Vector3(0.7071068f, 0, 0.7071068f) * range);
        Gizmos.DrawRay(transform.position, new Vector3(0, 0, 1) * range);
        Gizmos.color = Color.red;
        Gizmos.DrawRay(transform.position, new Vector3(0.9659258f, 0, 0.2588189f) * range);
        Gizmos.DrawRay(transform.position, new Vector3(0.9659258f, 0, -0.2588189f) * range);

        Gizmos.color = Color.gray;
        Gizmos.DrawRay(transform.position, new Vector3(0.5000001f, 0, 0.8660253f) * range);
        Gizmos.DrawRay(transform.position, new Vector3(0.8660253f, 0, 0.5000001f) * range);
              
        Gizmos.color = Color.black;                                               
        Gizmos.DrawRay(new Vector3(267.2102f, 0, 296.8264f), new Vector3(0.5000001f, 0, 0.8660253f) * range);
        Gizmos.color = Color.blue;
        Gizmos.DrawRay(new Vector3(292.7955f, 0, 276.9418f), new Vector3(0.8660253f, 0, 0.5000001f) * range);
                
        Gizmos.color = Color.cyan;
        Gizmos.DrawRay(transform.position, new Vector3(-0.2588189f, 0, 0.9659258f) * range);
        Gizmos.DrawRay(transform.position, new Vector3(0.2588189f, 0, 0.965925f) * range);

        Gizmos.color = Color.cyan;       
        Gizmos.DrawRay(new Vector3(296.8264f, 0, 267.2102f), new Vector3(0.9659258f, 0, 0.2588189f) * range);
        Gizmos.color = Color.gray;        
        Gizmos.DrawRay(new Vector3(292.7955f, 0, 235.0582f), new Vector3(0.9659258f, 0, -0.2588189f) * range);
               
    }
    // Update is called once per frame
    void Update()
    {
        for (int i = 0; i < 8; i++)
        {
            float RotationAngles = 2 * Mathf.PI / 8f * i;
            spheres[i, 0].transform.position = transform.position + new Vector3(Mathf.Cos(RotationAngles), 0, Mathf.Sin(RotationAngles)) * Radius;

            ArcDistn = Radius * RotationAngl;
            float dispersionAngle = (RotationAngl / 3f) + Mathf.PI / 2f;
            float coss = Mathf.Cos(dispersionAngle);
            float sinss = Mathf.Sin(dispersionAngle);
            Vector2 rotation = new Vector2(coss, sinss);

            Vector3 dir = (spheres[i, 0].transform.position - transform.position).normalized;
            float newX = dir.x * rotation.x - dir.z * rotation.y;
            float newY = dir.x * rotation.y + dir.z * rotation.x;

            float newX2 = dir.x * rotation.x + dir.z * rotation.y;
            float newY2 = dir.x * -rotation.y + dir.z * rotation.x; 

            float distArc = ArcDistn / 3f;
            Vector3 newPosLeft = new Vector3(newX, 0, newY) * distArc;
            Vector3 newPosRight = new Vector3(newX2, 0, newY2) * distArc;

            spheres[i, 1].transform.position = spheres[i, 0].transform.position + newPosLeft;
            spheres[i, 2].transform.position = spheres[i, 0].transform.position + newPosRight;
            
        }
       
        
    }
}
