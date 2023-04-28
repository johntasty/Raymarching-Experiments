using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//[ExecuteInEditMode]
public class PositionTest : MonoBehaviour
{

    [SerializeField]
    Material _Material;
    
    [SerializeField]
    Transform[] _Balls;
    [SerializeField]
    Transform _Target;
    [SerializeField]
    float _Force = 10f;
    [SerializeField]
    float radius = .5f;
    Vector4[] _BallsArray;
    public static Shape[] testing;

   
    static readonly int _BallPosArray = Shader.PropertyToID("_positions");

    struct ShapeData
    {
        public Vector3 position;
    }
    private void Start()
    {

        _BallsArray = new Vector4[1];
        int i = 0;
        foreach (Transform ball in _Balls)
        {
            _BallsArray[i] = new Vector4(ball.position.x, ball.position.y, ball.position.z, radius);
            i++;
        }
        _Material.SetVectorArray(_BallPosArray, _BallsArray);
    }
   
    private void Update()
    {
        if (_Material == null) return;
        
        float forceTime = _Force * Time.deltaTime;
        Vector3 PosTarget = _Target.position;
        for (int i = 0; i < _Balls.Length; i++)
        {
            Rigidbody _ball = _Balls[i].GetComponent<Rigidbody>();

            Vector3 direction = Vector3.Normalize(PosTarget - _Balls[i].position);
            Vector3 SeekForce = (direction * forceTime);

            _ball.velocity += SeekForce;
            Vector3 _PosLocal = new Vector3(_ball.position.x, _ball.position.y, _ball.position.z);
           
            _BallsArray[i] = new Vector4(_PosLocal.x, _PosLocal.y, _PosLocal.z, radius);
        }
              
        _Material.SetVectorArray(_BallPosArray, _BallsArray);
      
    }


}
