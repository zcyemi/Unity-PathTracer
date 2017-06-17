using System.Collections;
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

    private Vector3 pos;
    private Quaternion rota;


    private ComputeBuffer m_computeBuffer;
    [SerializeField]
    public CSGcontainer m_csg;

    public static PathTracerCamera Instance;

    private void Awake()
    {
        Instance = this;
        ResetRender();
        
    }
    // Use this for initialization
    void Start () {
		
	}

    private void checkCamera()
    {
        if (m_camera == null) m_camera = GetComponent<Camera>();
    }
	
	// Update is called once per frame
	void Update () {
        checkCamera();


        if (pos != m_camera.transform.position || rota != m_camera.transform.rotation)
        {
            ResetRender();
            pos = m_camera.transform.position;
            rota = m_camera.transform.rotation;
        }
	}

    public void UpdateBuffer()
    {
        if (m_csg == null) return;
        int stride = m_csg.GetStride();
        //Debug.Log("stride:" + stride);

        int count = m_csg.PrimitiveCount;
        //Debug.Log("count:" + count);
        if(m_computeBuffer == null)
            m_computeBuffer = new ComputeBuffer(count, m_csg.GetStride(), ComputeBufferType.Default);
        m_computeBuffer.SetData(m_csg.GetBufferData());
        mattracer.SetBuffer("_buffer", m_computeBuffer);
        mattracer.SetInt("_numberOfObjects", count);
    }

    public void OnDestroy()
    {
        if (m_computeBuffer != null)
            m_computeBuffer.Dispose();
        m_computeBuffer.Release();
        m_computeBuffer = null;
    }


    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (m_camera == null) m_camera = GetComponent<Camera>();

        var mtx= m_camera.projectionMatrix.inverse;
        mattracer.SetMatrix("_ProjInv", GetMtx());
        mattracer.SetFloat("_u_iterations", Iterator);
        if (rtex == null)
        {
            rtex = new RenderTexture(1920, 1080, 0);
        }
            
        if (rtex == null)
        {
            rtext = new RenderTexture(1920, 1080, 0);
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


    //public void OnDrawGizmos()
    //{
        
    //    for(int i=0;i<=10;i++)
    //    {
    //        for(int j=0;j<=10;j++)
    //        {
    //            DrawPoint(new Vector4(Mathf.Lerp(-1f, 1f, i / 10f), Mathf.Lerp(-1f, 1f, j / 10f), 1f, 1f));
    //        }
    //    }
    //}

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
        Gizmos.DrawSphere(m_camera.transform.position+ new Vector3(pos.x, pos.y, pos.z) * z, 0.1f);
    }

    public void ResetRender()
    {
        Iterator = 0;
        rtex.DiscardContents(true, true);
        rtext.DiscardContents(true, true);

        UpdateBuffer();
    }
}
