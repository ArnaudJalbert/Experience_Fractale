using System;
using UnityEngine;

namespace Fractals
{
    [Serializable]
    public class Fractal
    {
        [SerializeField] private Vector4 _coords;

        [SerializeField] private float _scale;

        [SerializeField] private int _repetitions;

        public Vector4 Coords
        {
            get => _coords;
            set => _coords = value;
        }

        public float Scale
        {
            get => _scale;
            set => _scale = value;
        }
    
        public int Repetitions
        {
            get => _repetitions;
            set => _repetitions = value;
        }
    }
}