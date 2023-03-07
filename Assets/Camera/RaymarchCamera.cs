using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using System.IO;
using Unity.VisualScripting;


[RequireComponent(typeof(Camera))]
 [ExecuteInEditMode]

 public class RaymarchCamera : SceneViewFilter
 {
     // shader file
     [Header("Shader File")] [SerializeField]
     private Shader shader;
     
     [Range(1,100000)] [SerializeField] private int maxIterations = 300;

     [Range(0.1f, 0.000000001f)] [SerializeField] private float accuracy = 0.0001f;
     
     // Camera ------------
     private Camera _cam;
    
     [Header("Camera")]
     [SerializeField] private float maxDistance = 1000f;

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
     
     // Geometry -------------------------
     
     private static int _mengerSpongesQuantity = 5;
     [Header("Geometry")] 
     [SerializeField] private List<MengerSponge> mengerSponges = new List<MengerSponge>(_mengerSpongesQuantity);

     [SerializeField] private bool animateMengerSponges; 
     [SerializeField] private float mengerSpongesAnimateSpeed; 
     
     private List<Vector4> GetMengerSpongesVectors()
     {
         List<Vector4> mengerSpongesVector = new List<Vector4>();
         
         foreach (var mengerSponge in mengerSponges)
         {
             mengerSpongesVector.Add(mengerSponge.Coords);
         }

         return mengerSpongesVector;
     }
     
     private List<float> GetMengerSpongesScales()
     {
         List<float> mengerSpongesScales = new List<float>();
         
         foreach (var mengerSponge in mengerSponges)
         {
             mengerSpongesScales.Add(mengerSponge.Scale);
         }

         return mengerSpongesScales;
     }
     
     private List<float> GetMengerSpongesRepetitions()
     {
         List<float> getMengerSpongesRepetitions = new List<float>();
         
         foreach (var mengerSponge in mengerSponges)
         {
             getMengerSpongesRepetitions.Add(mengerSponge.Repetitions);
         }

         return getMengerSpongesRepetitions;
     }
     
     //-----------
     
     // Geometry -------------------------
     
     private static int _mandelbulbQuantity = 5;
     [SerializeField] private List<Mandelbulb> mandelbulbs = new List<Mandelbulb>(_mandelbulbQuantity);

     [SerializeField] private bool animateMandelbulb;
     [SerializeField] private float animateSpeed;
     private List<Vector4> GetMandelbulbVectors()
     {
         List<Vector4> mandelbulbsVector = new List<Vector4>();
         
         foreach (var mandelbulb in mandelbulbs)
         {
             mandelbulbsVector.Add(mandelbulb.Coords);
         }

         return mandelbulbsVector;
     }
     
     private List<float> GetMandelbulbScales()
     {
         List<float> getMandelbulbScales = new List<float>();
         
         foreach (var mandelbulb in mandelbulbs)
         {
             getMandelbulbScales.Add(mandelbulb.Scale);
         }

         return getMandelbulbScales;
     }
     
     private List<float> GetMandelbulbRepetitions()
     {
         List<float> getMandelbulbRepetitions = new List<float>();
         
         foreach (var mandelbulb in mandelbulbs)
         {
             getMandelbulbRepetitions.Add(mandelbulb.Repetitions);
         }

         return getMandelbulbRepetitions;
     }

     private List<float> GetMandelbulbIterations()
     {
         List<float> getMandelbulbIterations = new List<float>();
         
         foreach (var mandelbulb in mandelbulbs)
         {
             getMandelbulbIterations.Add(mandelbulb.Iterations);
         }

         return getMandelbulbIterations;
     }
     
     //-----------

     
     // repeat
     [SerializeField] private float modRepeatX;
     [SerializeField] private float modRepeatY;
     [SerializeField] private float modRepeatZ;
     [SerializeField] private bool switchRepeatX;
     [SerializeField] private bool switchRepeatY;
     [SerializeField] private bool switchRepeatZ;

     [SerializeField] private Color mainColor = Color.grey;

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

    // Light + Shading ------------------
    [Header("Shading")]
    [SerializeField] private Transform directionalLight;

    [SerializeField] private Color lightColor = Color.white;

    [SerializeField] private float lightIntensity = 1;

    [SerializeField] private Vector2 shadowDistance = new Vector2(1.0f, 20.0f);

    [SerializeField] private float shadowIntensity = 1;

    [SerializeField] private float shadowPenumbra = 5.0f;
    //-------------------------
    
    //------------------
    // ambient occlusion
    [Header("Ambien Occlusion")]

    [Range(0.1f, 10f)][SerializeField] private float aoStepSize = 1.0f;
    
    [Range(1,5)][SerializeField] private int aoIterations = 2;
    
    [Range(0f, 1f)][SerializeField] private float aoIntensity = 0.5f;
    //------------------
    private int getSwicthInteger(bool modSwitch)
    {
        if (modSwitch)
        {
            return 1;
        }

        return 0;
    }

    private void InitShaderParams()
    {

        // ambient occlusion
        RaymarchMaterial.SetInteger("_AoIterations", aoIterations);
        RaymarchMaterial.SetFloat("_Accuracy", accuracy);
        RaymarchMaterial.SetFloat("_AoStepSize", aoStepSize);
        RaymarchMaterial.SetFloat("_AoIntensity", aoIntensity);
        
        // geometry
        RaymarchMaterial.SetVector("_MainColor", mainColor);
        RaymarchMaterial.SetFloat("_MaxDistance", maxDistance);
        
        
        if (mengerSponges.Count > 0 && mengerSponges.Count <= 5)
        {
            RaymarchMaterial.SetInteger("_MengerSpongesLimit", 5);
            RaymarchMaterial.SetFloatArray("_MengerSpongesScales", GetMengerSpongesScales());
            RaymarchMaterial.SetVectorArray("_MengerSpongesVectors", GetMengerSpongesVectors());
            RaymarchMaterial.SetFloatArray("_MengerSpongesRep", GetMengerSpongesRepetitions());
            
        }
        
        if (mandelbulbs.Count > 0 && mandelbulbs.Count <= 5)
        {
            RaymarchMaterial.SetInteger("_MandelbulbsLimit", mandelbulbs.Count);
            RaymarchMaterial.SetFloatArray("_MandelbulbsScales", GetMandelbulbScales());
            RaymarchMaterial.SetVectorArray("_MandelbulbsVectors", GetMandelbulbVectors());
            RaymarchMaterial.SetFloatArray("_MandelbulbsRep", GetMandelbulbRepetitions());
            RaymarchMaterial.SetFloatArray("_MandelbulbsIterations", GetMandelbulbIterations());
            
        }

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
    }
    
    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (!RaymarchMaterial)
        {
            // sends source texture to destination texture with the shader
            Graphics.Blit(src, dest);
            return;
        }

        InitShaderParams();
        
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

    
    static public void ClearShaderCache_Command()
    {
        var shaderCachePath = Path.Combine( Application.dataPath , "../Library/ShaderCache");
        Directory.Delete( shaderCachePath , true );
    }

    public override void OnValidate()
    {
        base.OnValidate();

    }
    
    
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        if(animateMandelbulb)
        {
            foreach (var mandelbulb in mandelbulbs)
            {
                if (mandelbulb.Iterations < 1)
                {
                    mandelbulb.Iterations = 1;
                    
                }
                mandelbulb.Iterations = (mandelbulb.Iterations + animateSpeed) % 16;
            }
        }

        if (animateMengerSponges)
        {
            foreach (var mengerSponge in mengerSponges)
            {
                
                if (mengerSponge.Scale > 5 || mengerSponge.Scale < -5)
                {
                    mengerSponge.Scale = -5;
                }

                if (mengerSponge.Scale > -3.6 && mengerSponge.Scale < -2.7)
                {
                    mengerSponge.Scale = -2.6f;
                }
                mengerSponge.Scale = mengerSponge.Scale + mengerSpongesAnimateSpeed % 10;
            }
        }
    }
}
