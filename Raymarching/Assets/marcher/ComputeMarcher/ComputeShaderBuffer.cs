using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ComputeShaderBuffer : MonoBehaviour
{

    ComputeBuffer bufferShapes;
    [SerializeField]
    ComputeShader _Compute;
    [SerializeField]
    int numShapes;
    public static Shape[] testing;
    Shape shapeData;
    [SerializeField]
    GameObject ballPrefab;
    [SerializeField]
    Transform ballParent;
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
        public Vector3[] position;
    }

    private void Start()
    {
        kernelIndex = _Compute.FindKernel("InvertColors");

        Vector3[] position = new Vector3[numShapes];
        _Balls = new Transform[numShapes];
        for (int i = 0; i < numShapes; i++)
        {
            Vector3 rand = Random.insideUnitSphere * 3;
            GameObject ball = Instantiate(ballPrefab, rand, Quaternion.identity,ballParent);
            _Balls[i] = ball.transform;
            position[i] = rand;
        }
       
        bufferShapes = new ComputeBuffer(numShapes, sizeof(float) * 3);
               
        //mComputeShaderKernelID = _Compute.FindKernel("CSMain");
        bufferShapes.SetData(position);
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
    //    _Compute.SetBuffer(kernelIndex, "shapes", bufferShapes);
    //    //testing = shapeData;

    //}
}
