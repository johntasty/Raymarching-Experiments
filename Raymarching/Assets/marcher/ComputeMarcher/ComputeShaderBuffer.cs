using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ComputeShaderBuffer : MonoBehaviour
{
    public float xFloat;
    public float yFloat;
    public float zFloat;
    public float result;

    ComputeBuffer bufferShapes;
    [SerializeField]
    ComputeShader _Compute;
    [SerializeField]
    int numShapes;
    public static Shape[] testing;
    Shape[] shapeData;

    [SerializeField]
    Transform[] _Balls;
    [SerializeField]
    Transform _Target;
    [SerializeField]
    float _Force = 10f;
    private int mComputeShaderKernelID;
    private int kernelIndex;

    struct ShapeData
    {
        public Vector3 position;
    }

    private void Start()
    {
        kernelIndex = _Compute.FindKernel("InvertColors");
        

        shapeData = new Shape[numShapes];
        for (int i = 0; i < numShapes; i++)
        {
            Vector3 rand = Random.insideUnitSphere * 3;
            shapeData[i].position = rand;
        }
        //int i = 0;
        //foreach (Transform ball in _Balls)
        //{
        //    Vector3 rand = Random.insideUnitSphere * 3;
        //    ball.position += rand;
        //    shapeData[i].position = new Vector3(ball.position.x, ball.position.y, ball.position.z);
        //    i++;
        //}
        //testing = shapeData;
        bufferShapes = new ComputeBuffer(numShapes, sizeof(float) * 3);
               
        //mComputeShaderKernelID = _Compute.FindKernel("CSMain");
        bufferShapes.SetData(shapeData);
        _Compute.SetBuffer(kernelIndex, "shapes", bufferShapes);
       
        
    }
    private void OnDestroy()
    {
        if (bufferShapes != null)
            bufferShapes.Release();
    }
       
    //private void Update()
    //{
    //    float forceTime = _Force * Time.deltaTime;
    //    Vector3 PosTarget = _Target.position;
    //    for (int i = 0; i < _Balls.Length; i++)
    //    {
    //        Rigidbody _ball = _Balls[i].GetComponent<Rigidbody>();

    //        Vector3 direction = Vector3.Normalize(PosTarget - _Balls[i].position);
    //        Vector3 SeekForce = (direction * forceTime);

    //        _ball.velocity += SeekForce;
    //        Vector3 _PosLocal = new Vector3(_ball.position.x, _ball.position.y, _ball.position.z);
    //        shapeData[i].position = new Vector3(_PosLocal.x, _PosLocal.y, _PosLocal.z);

    //    }
    //    bufferShapes.SetData(shapeData);
    //    //testing = shapeData;

    //}
}
