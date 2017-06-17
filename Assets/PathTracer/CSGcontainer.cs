using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;

[Serializable]
public struct Primitive
{
    public Vector4 pos;
    public Vector4 param;
    public Vector4 color;
    public int type;
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
        return sizeof(float) * 12 + sizeof(int);
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
