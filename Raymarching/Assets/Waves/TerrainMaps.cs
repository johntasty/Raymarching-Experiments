using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TerrainMaps : MonoBehaviour
{
    [SerializeField]
    Terrain _TerrainObject;
    TerrainData _terrain;
    [SerializeField]
    Material riverMat;

    private void Start()
    {
        GetMap();
    }
    void GetMap()
    {
        _terrain = _TerrainObject.terrainData;
        RenderTexture map = _terrain.heightmapTexture;
        riverMat.SetTexture("_MainTex", map);
    }
}
