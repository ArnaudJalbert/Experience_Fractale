// basic menger spone functions

#ifndef MENGER_SPONE
#define MENGER_SPONE

#include "Primitives.cginc"

float maxcomp(in float3 p ) { return max(p.x,max(p.y,p.z));}

float spongeBox( float3 p, float3 b )
{
    float3  di = abs(p) - b;
    float mc = maxcomp(di);
    return min(mc,length(max(di,0.0)));
}

float cross(float3 p)
{
    float da = max(p.x,p.y);
    
    float db = max(p.y,p.z);
    
    float dc = max(p.z,p.x);
    
    return min(da,min(db,dc))-1.0;
}


// InfBox
// b: size of box in x/y/z
float sd2DBox( in float2 p, in float2 b )
{
    float2 d = abs(p)-b;
    return length(max(d,float2(0,0))) + min(max(d.x,d.y),0.0);
}

// Cross
// s: size of cross
float sdCross( in float3 p, float b )
{
    float da = sd2DBox(p.xy,float2(b,b));
    float db = sd2DBox(p.yz,float2(b,b));
    float dc = sd2DBox(p.zx,float2(b,b));
    return min(da,min(db,dc));
}


float pMod ( float p, float size)
{
    float halfsize = size * 0.5;
    float c = floor((p+halfsize)/size);
    p = fmod(p+halfsize,size)-halfsize;
    p = fmod(p-halfsize,size)+halfsize;
    return p;
}

float2 map(float3 p, float scale, float size, int rep)
{
    
    float2 d = float2(spongeBox(p, float3(size, size, size)), 0);

    float s = 3.0 + scale;

    for (int i = 0; i < rep; i++)
    {
        p.x = pMod(p.x, 2/s);
        p.y = pMod(p.y, 2/s);
        p.z = pMod(p.z, 2/s);

        s *= 3.0;

        float3 r =(p)*s;
        
        float c = (sdCross(r, 2))/s;

        if(c>d.x)
        {
            d.x = c;
            d = float2( d.x, i);
            
        }
        
    }

    return d;
}




#endif