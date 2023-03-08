using System;
using Fractals;
using UnityEngine;

[Serializable]
public class Mandelbulb: Fractal
{
    [SerializeField] private float iterations;

    public float Iterations
    {
        get => iterations;
        set => iterations = value;
    }
}