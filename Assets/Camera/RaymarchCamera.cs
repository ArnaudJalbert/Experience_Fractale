 using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.GlobalIllumination;

 [RequireComponent(typeof(Camera))]
 [ExecuteInEditMode]

 public class RaymarchCamera : SceneViewFilter
 {
     // shader file
     [Header("Shader File")] [SerializeField]
     private Shader shader;
     
     [Range(1,300)] [SerializeField] private int maxIterations;

     [Range(0.1f, 0.00001f)] [SerializeField] private float accuracy;
     
     // Geometry -------------------------
     [Header("Geometry")] [SerializeField] private Vector4 testSphere;
     [SerializeField] private Vector4 testBox;
     
     // repeat
     [SerializeField] private float modRepeatX;
     [SerializeField] private float modRepeatY;
     [SerializeField] private float modRepeatZ;
     
     [SerializeField] private bool switchRepeatX;
     [SerializeField] private bool switchRepeatY;
     [SerializeField] private bool switchRepeatZ;

     [SerializeField] private Color mainColor;
    //-----------------------------------
    
    // Material ------------
    private Material _raymarchMaterial;

    public Material RaymarchMaterial
    {
        get
        {
            if (!_raymarchMaterial && shader)
            {
                _raymarchMaterial = new Material(shader);
                _raymarchMaterial.hideFlags = HideFlags.HideAndDontSave;
            }
            return _raymarchMaterial;
        }
    }
    //----------------------

    // Camera ------------
    private Camera _cam;
    
    [Header("Camera")]
    [SerializeField] private float maxDistance;

    public Camera Cam
    {
        get
        {
            if (!_cam)
            {
                _cam = GetComponent<Camera>();
            }
            return _cam;
        }
    }
    //------------------
    
    // Light + Shading ------------------
    [Header("Shading")]
    [SerializeField] private Transform directionalLight;

    [SerializeField] private Color lightColor;

    [SerializeField] private float lightIntensity;

    [SerializeField] private Vector2 shadowDistance;

    [SerializeField] private float shadowIntensity;

    [SerializeField] private float shadowPenumbra;
    //-------------------------
    
    //------------------
    // ambient occlusion
    [Header("Ambien Occlusion")]

    [Range(0.1f, 10f)][SerializeField] private float aoStepSize;
    
    [Range(1,5)][SerializeField] private int aoIterations;
    
    [Range(0f, 1f)][SerializeField] private float aoIntensity;

    private int getSwicthInteger(bool modSwitch)
    {
        if (modSwitch)
        {
            return 1;
        }

        return 0;
    }
    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (!RaymarchMaterial)
        {
            // sends source texture to destination texture with the shader
            Graphics.Blit(src, dest);
            return;
        }
        
        // ambient occlusion
        RaymarchMaterial.SetInteger("_AoIterations", aoIterations);
        RaymarchMaterial.SetFloat("_Accuracy", accuracy);
        RaymarchMaterial.SetFloat("_AoStepSize", aoStepSize);
        RaymarchMaterial.SetFloat("_AoIntensity", aoIntensity);
        
        // geometry
        RaymarchMaterial.SetVector("_MainColor", mainColor);
        RaymarchMaterial.SetFloat("_MaxDistance", maxDistance);
        RaymarchMaterial.SetVector("_TestSphere", testSphere);
        RaymarchMaterial.SetVector("_TestBox", testBox);
        
        // repeats
        RaymarchMaterial.SetFloat("_ModRepeatX", modRepeatX);
        RaymarchMaterial.SetFloat("_ModRepeatY", modRepeatY);
        RaymarchMaterial.SetFloat("_ModRepeatZ", modRepeatZ);
        
        RaymarchMaterial.SetInteger("_SwitchRepeatX", getSwicthInteger(switchRepeatX));
        RaymarchMaterial.SetInteger("_SwitchRepeatY", getSwicthInteger(switchRepeatY));
        RaymarchMaterial.SetInteger("_SwitchRepeatZ", getSwicthInteger(switchRepeatZ));
        
       // camera 
       RaymarchMaterial.SetInteger("_MaxIterations", maxIterations);
        RaymarchMaterial.SetMatrix("_CamFrustum", CamFrustum(Cam));
        RaymarchMaterial.SetMatrix("_CamToWorld", Cam.cameraToWorldMatrix);
        
        // shading
        RaymarchMaterial.SetVector("_LightDirection", directionalLight ? directionalLight.forward : Vector3.up);
        RaymarchMaterial.SetVector("_LightColor", lightColor);
        RaymarchMaterial.SetFloat("_LightIntensity", lightIntensity);
        RaymarchMaterial.SetVector("_ShadowDistance", shadowDistance);
        RaymarchMaterial.SetFloat("_ShadowIntensity", shadowIntensity);
        RaymarchMaterial.SetFloat("_ShadowPenumbra", shadowPenumbra);

        // setting the texture 
        RenderTexture.active = dest;
        RaymarchMaterial.SetTexture("_MainTex", src);
        // pushing the defined matrix 
        GL.PushMatrix();
        // setting up an orthographic projection 
        GL.LoadOrtho();
        // specifying which pass to use
        RaymarchMaterial.SetPass(0);
        // start drawing 3D primitive(quads specifically)
        GL.Begin(GL.QUADS);
        
        // setting the corners of the screen
        
        // bottom left
        GL.MultiTexCoord2(0, 0.0f, 0.0f);
        GL.Vertex3(0.0f, 0.0f, 3.0f);
        
        // bottom right
        GL.MultiTexCoord2(0, 1.0f, 0.0f);
        GL.Vertex3(1.0f, 0.0f, 2.0f);
        
        // top right
        GL.MultiTexCoord2(0, 1.0f, 1.0f);
        GL.Vertex3(1.0f, 1.0f, 1.0f);
        
        // top left
        GL.MultiTexCoord2(0, 0.0f, 1.0f);
        GL.Vertex3(0.0f, 1.0f, 0.0f);
        
        GL.End();
        GL.PopMatrix();
    }

    // allows to get the 4 directions that maps to the 4 corners of the render screen
    private Matrix4x4 CamFrustum(Camera cam)
    {
        // see COMP371 notes for explanation of this
        
        Matrix4x4 frustum = Matrix4x4.identity;
        
        // allows us to get the Z position of the render screen
        float fov = Mathf.Tan((cam.fieldOfView * 0.5f) * Mathf.Deg2Rad);
        
        // we go up starting from Z position of the render screen
        Vector3 goUp = Vector3.up * fov;
        // we go right starting from Z position of the render screen
        Vector3 goRight = Vector3.right * fov * cam.aspect;
        
        // get the 4 corners
        Vector3 topLeft = (-Vector3.forward - goRight + goUp);
        Vector3 topRight = (-Vector3.forward + goRight + goUp);
        Vector3 bottomRight = (-Vector3.forward + goRight - goUp);
        Vector3 bottomLeft = (-Vector3.forward - goRight - goUp);

        // setting the row of the matrix to the corners
        frustum.SetRow(0, topLeft);
        frustum.SetRow(1, topRight);
        frustum.SetRow(2, bottomRight);
        frustum.SetRow(3, bottomLeft);
        
        return frustum;
    }

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
