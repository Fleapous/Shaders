using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GeneratePlane : MonoBehaviour
{

    [SerializeField] private int size;
    [SerializeField] private int dist;
    [SerializeField] private bool debugSize;
    [SerializeField] private bool asyncChunkGen;
    
    private Mesh mesh;
    private List<Vector3> vectorList;
    private List<int> tris;
    private List<Vector2> uv;

    private MeshFilter _meshFilter;
    private MeshRenderer _meshRenderer;

    void Start()
    {
        if(!debugSize)
            PlaneGenerationWrapperFunctionAsync(size);
    }

    private void OnValidate()
    {
        if(debugSize)
            PlaneGenerationWrapperFunctionAsync(size);
    }

    void MakeVertex(int n, List<Vector3> vectors, List<Vector2> uvCords)
    {
        Debug.Log(debugSize);
        // n *= dist;
        for (int i = 0; i < n; i++)
        {
            for (int j = 0; j < n; j++)
            {
                float x = dist * (1/10) * j;
                float z = dist * (1/10) * i;
                vectors.Add(new Vector3((float)j / dist, 0, (float)i / dist));
                uvCords.Add(new Vector2(j/(float)n, i/(float)n));
                
                // float x = 1/dist * j;
                // float z = 1/dist * i;
                // vectors.Add(new Vector3((float)j / dist, 0, (float)i / dist));
                // uvCords.Add(new Vector2(j / (float)(n - 1), i / (float)(n - 1)));
            }
        }
    }

    void MakeTris(int n, List<int> ints)
    {
        int k = 0;
        for (int i = 0; i < Mathf.Pow(n -1, 2); i++)
        {
            ints.Add(k);
            ints.Add(k + n);
            ints.Add(k + 1);
            
            ints.Add(k + 1);
            ints.Add(k + n);
            ints.Add(k + n + 1);
            
            if ((k + 1) % n == n - 1)
                k++;
            k++;
        }
    }
    
    private async void PlaneGenerationWrapperFunctionAsync(int size_)
    {
        Debug.Log("matrix start");
        MeshFilter meshFilter = GetComponent<MeshFilter>();
        vectorList = new List<Vector3>();
        tris = new List<int>();
        uv = new List<Vector2>();
        mesh = new Mesh();
        GetComponent<MeshFilter>().mesh = mesh;

        MakeVertex(size_, vectorList, uv);
        MakeTris(size_, tris);

        Vector3[] vectorArr = vectorList.ToArray();
        int[] trisArr = tris.ToArray();
        Vector2[] uvArr = uv.ToArray();

        mesh.Clear();
        mesh.vertices = vectorArr;
        mesh.triangles = trisArr;
        mesh.uv = uvArr;
        meshFilter.mesh = mesh;
        mesh.RecalculateNormals();
    }
}
