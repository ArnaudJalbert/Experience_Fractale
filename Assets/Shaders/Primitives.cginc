// ----------------
// primitive shapes

#ifndef PRIMITIVES
#define PRIMITIVES

#define INFINTY 999999999999999.0

string test = "allo";


// alterations if wanted
float elongate(in float3 p, in float3 h )
{
	float3 q = abs(p)-h;
	return max(q,0.0) + min(max(q.x,max(q.y,q.z)),0.0);
}

// p: current point

// Sphere
// s: radius
float sphere(float3 p, float s)
{
	return length(p) - s;
}

// Box
// b: size of box in x/y/z
float box(float3 p, float3 b)
{
	float3 d = abs(p) - b;
	return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

// Round Box
// b: size of box in x/y/z
// r: radius of roundness of the box
float roundBox(float3 p, float3 b, float r)
{
	return box(p, b) - r;
}

// Box Frame
// b: size of box in x/y/z
// e: extrusion
float boxFrame(float3 p, float3 b, float e)
{
	p = abs(p) - b;
	float3 d = abs(p + e) - e;

	float3 x = min(
	  length(max(float3(p.x,d.y,d.z),0.0))+min(max(p.x,max(d.y,d.z)),0.0),
	  length(max(float3(d.x,p.y,d.z),0.0))+min(max(d.x,max(p.y,d.z)),0.0)
	  );

	float3 y = length(max(float3(d.x,d.y,p.z),0.0))+min(max(d.x,max(d.y,p.z)),0.0);

	return min(x,y);
}

// Torus
// r: radius of the torus
// h: "height" of the torus
float torus(float3 p, float r, float h)
{
	float2 d = float2(length(p.xz) - r, p.y);
	return length(d) - h;
}

// Link
// le: length
// r1: inner radius of the hole
// r2: radius of the shape
float link(float3 p, float le, float r1, float r2)
{
	float3 d = float3(p.x, max(abs(p.y)-le, 0.0), p.z);
	return length(float2(length(d.xy)-r1,d.z)) - r2;
}

// Round Cylinder
// ra: radius of middle cylinder
// rb: height of the top of cylinder
// h: height of the cylinder
float roundCylinder( float3 p, float ra, float rb, float h )
{
	float2 d = float2( length(p.xz)-2.0*ra+rb, abs(p.y) - h );
	return min(max(d.x,d.y),0.0) + length(max(d,0.0)) - rb;
}

// infinite plane
// n: normal of the plane
float infinitePlane( float3 p, float4 n )
{
	// n must be normalized
	return dot(p,n) + n.w;
}

// plane
// n: normal of the plane
// h: height of the plabe
float plane( float3 p, float4 n, float h)
{
	// n must be normalized
	normalize(n);
	return dot(p,n) + h;
}

// Octahedron
// s: size of the shape
float octahedron( float3 p, float s)
{
	p = abs(p);
	return (p.x+p.y+p.z-s)*0.57735027;
}


// Cut Hollow Sphere
// r: radius of the cut
// h: height of the cut
// t: size of the sphere
float cutHollowSphere(float3 p, float r, float h, float t)
{
	// sampling independent computations (only depend on shape)
	float w = sqrt(r*r-h*h);
  
	// sampling dependant computations
	float2 q = float2( length(p.xz), p.y );
	return ((h*q.x<w*q.y) ? length(q-float2(w,h)) : 
							abs(length(q)-r) ) - t;
}


// Death Star
float deathStar( float3 p2, float ra, float rb, in float d )
{
  // sampling independent computations (only depend on shape)
  float a = (ra*ra - rb*rb + d*d)/(2.0*d);
  float b = sqrt(max(ra*ra-a*a,0.0));
	
  // sampling dependant computations
  float2 p = float2( p2.x, length(p2.yz) );
  if( p.x*b-p.y*a > d*max(b-p.y,0.0) )
  	return length(p-float2(a,b));
	else
		return max( (length(p          )-ra),
				   -(length(p-float2(d,0))-rb));
	}
// ----------------

// BOOLEAN OPERATORS //

// Union
float shapeUnion(float d1, float d2)
{
	return min(d1, d2);
}

// Subtraction
float shapeSubtraction(float d1, float d2)
{
	return max(-d1, d2);
}

// Intersection
float shapeIntersection(float d1, float d2)
{
	return max(d1, d2);
}

// Mod Position Axis
float modAxis (inout float p, float size)
{
	float halfsize = size * 0.5;
	float c = floor((p+halfsize)/size);
	p = fmod(p+halfsize,size)-halfsize;
	p = fmod(-p+halfsize,size)-halfsize;
	return c;
}

#endif