﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
public class PathTracerCamera : MonoBehaviour {

    public RenderTexture rtex;
    public RenderTexture rtext;
    public Material mattracer;

    public float z = 1.0f;
    public float Iterator;

    private Camera m_camera;

    private void Awake()
    {
        ResetRender();
    }
    // Use this for initialization
    void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {
		
	}

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (m_camera == null) m_camera = GetComponent<Camera>();

        var mtx= m_camera.projectionMatrix.inverse;
        mattracer.SetMatrix("_ProjInv", GetMtx());
        mattracer.SetFloat("_u_iterations", Iterator);
        if (rtex == null || rtext == null)
        {
            rtex = new RenderTexture(1920, 1080, 0, RenderTextureFormat.Default);
            rtext = new RenderTexture(1920, 1080, 0, RenderTextureFormat.Default);
        }

        //Graphics.Blit(source, destination);

        if (mattracer != null)
        {
            
            Graphics.Blit(rtex, rtext, mattracer);
            Graphics.Blit(rtext, rtex);
            var rect = m_camera.rect;
            m_camera.rect = new Rect(0, 0, 1.0f, 1.0f);
            Graphics.Blit(rtex, destination);
            m_camera.rect = rect;

            Iterator += 1.0f;

        }
    }


    public void OnDrawGizmos()
    {
        for(int i=0;i<=10;i++)
        {
            for(int j=0;j<=10;j++)
            {
                DrawPoint(new Vector4(Mathf.Lerp(-1f, 1f, i / 10f), Mathf.Lerp(-1f, 1f, j / 10f), 1f, 1f));
            }
        }
    }

    public Matrix4x4 GetMtx()
    {
        if (m_camera == null) m_camera = GetComponent<Camera>();
        return m_camera.cameraToWorldMatrix * m_camera.projectionMatrix.inverse;
    }

    public void DrawPoint(Vector4 pos)
    {
        if (m_camera == null) m_camera = GetComponent<Camera>();
        var mtx = m_camera.projectionMatrix.inverse;
        pos = m_camera.cameraToWorldMatrix * mtx * pos;
        Gizmos.DrawSphere(new Vector3(pos.x, pos.y, pos.z) * z, 0.1f);
    }

    public void ResetRender()
    {
        Iterator = 0;
        if (rtex != null)
            rtex.DiscardContents();
        if(rtext != null)
            rtext.DiscardContents();
        

        rtex = null;
        rtext = null;
    }
}