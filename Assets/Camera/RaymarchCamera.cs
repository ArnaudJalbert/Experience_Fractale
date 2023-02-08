using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Camera))]

public class RaymarchCamera : MonoBehaviour
{
    
    // Unity Parameters ------------------
    [SerializeField] private Shader shader;
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
    private Camera _camera;

    public Camera Camera
    {
        get
        {
            if (!_camera)
            {
                _camera = GetComponent<Camera>();
            }
            return _camera;
        }
    }
    //------------------

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (!_raymarchMaterial)
        {
            Graphics.Blit(src, dest);
        }
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
