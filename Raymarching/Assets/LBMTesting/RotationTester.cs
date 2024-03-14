using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RotationTester : MonoBehaviour
{
    public Vector2 _X_Y;

    public float Result;
    public float Resultx;
    public Vector2 ResultXX;

    // Start is called before the first frame update
   

    // Update is called once per frame
    void Update()
    {
        float di = Vector2.Dot(_X_Y, Vector2.right);
        Resultx = Mathf.Sqrt(Vector2.Dot(_X_Y, _X_Y)) * 1f;
        Result = Mathf.Acos(di / Resultx);
        ResultXX = new Vector2(Vector2.right.x * Mathf.Cos(Result) - Vector2.right.y * Mathf.Sin(Result), Vector2.right.x * Mathf.Sin(Result) + Vector2.right.y * Mathf.Cos(Result)).normalized;


    }
}
