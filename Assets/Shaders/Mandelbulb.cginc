#ifndef MANDELBULB
#define MANDELBULB

float2 mandelbulbMap( float3 p, int rep, float n)
{

    float3 zeta = p;

    float m = dot(zeta,zeta);

    float dz = 1.0f;

    for (int i = 0; i < rep; i++)
    {
        dz = n*pow(m,(n-1)/2)*dz + 1.0;
        
        float r = sqrt(dot(zeta,zeta));
        float phi = acos(zeta.y/r);
        float theta = atan2(zeta.x,zeta.z);

        r = pow( r, n );
        phi = phi * n;
        theta = theta * n;
        

        zeta = p + r * float3( sin(phi)*sin(theta), cos(phi), sin(phi)*cos(theta));

        m = dot(zeta,zeta);
        if( m > n*n )
            break;
    }
    
    return 0.05*log(m)*sqrt(m)/dz;
    
}


#endif