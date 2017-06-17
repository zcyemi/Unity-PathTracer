using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;

[Serializable]
public struct Primitive
{
    public Vector3 pos;
    public Vector3 param;
    public int type;
}

[Serializable]
public class CSGcontainer : MonoBehaviour {

    private float m_containerSize = 5f;
    [SerializeField]
    public List<Primitive> objs = new List<Primitive>();

    void Start () {
		
	}
	
	void Update () {
		
	}

    public int GetStride()
    {
        return sizeof(float) * 6 + sizeof(int);
    }

    public Primitive[] GetBufferData()
    {
        return objs.ToArray();
    }

    private void OnDrawGizmos()
    {
        foreach(var p in objs)
        {
            switch(p.type)
            {
                case 0:
                    Gizmos.DrawSphere(p.pos, p.param.x);
                    break;
            }
        }

        Gizmos.DrawWireCube(Vector3.zero, Vector3.one * m_containerSize);
    }
}
