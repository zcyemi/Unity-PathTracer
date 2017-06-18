using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using System.Runtime.InteropServices;

[Serializable]
[StructLayout(LayoutKind.Sequential)]
public struct Primitive
{
    [SerializeField]
    public Vector4 pos;
    [SerializeField]
    public float reflective;
    [SerializeField]
    public float refractive;
    [SerializeField]
    public float reflectivity;
    [SerializeField]
    public float indexOfRefraction;
    [SerializeField]
    public Vector3 color;
    [SerializeField]
    public float emmitance;
    [SerializeField]
    public float type;

    [SerializeField]
    public float mat1;
    [SerializeField]
    public float mat2;
    [SerializeField]
    public float mat3;
}

[ExecuteInEditMode]
[Serializable]
public class CSGcontainer : MonoBehaviour {

    private float m_containerSize = 5f;
    [SerializeField]
    private List<CSGPrimitive> m_primitives = new List<CSGPrimitive>();


    public int PrimitiveCount { get { return m_primitives.Count; } }


    void Start () {
		
	}
	
	void Update () {
        transform.position = Vector3.zero;
        transform.rotation = Quaternion.identity;
	}

    public int GetStride()
    {
        return sizeof(float) * 16;
    }

    public Primitive[] GetBufferData()
    {
        CSGPrimitive[] childs = transform.GetComponentsInChildren<CSGPrimitive>();
        List<Primitive> ps = new List<Primitive>();
        foreach(var c in childs)
        {
            c.UpdateData();
            ps.Add(c.Data);
        }

        return ps.ToArray();
    }

    public void AddPrimitive()
    {
        GameObject g = new GameObject("primitive");

        var p = g.AddComponent<CSGPrimitive>();
        m_primitives.Add(p);

        g.transform.SetParent(transform);
        g.transform.localPosition = Vector3.zero;

    }

    private void OnDrawGizmos()
    {

        Gizmos.DrawWireCube(Vector3.zero, Vector3.one * m_containerSize);
    }
}
