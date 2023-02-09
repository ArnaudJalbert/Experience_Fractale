// changed from "Hidden" to "PeerPlay"
// not sure if this is ok
Shader "PeerPlay/RaymarchShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // adding a target
            #pragma target 3.0

            #include "UnityCG.cginc"

            #define MAX_RAYMARCH_ITERATIONS 256
            #define DISTANCE_EPSILON 0.001f
            #define OFFSET (float2(0.001,0))
            

            // parameters
            sampler2D _MainTex;
            // maximum distance the ray is allowed to travel
            uniform float _MaxDistance;
            // sphere for testing
            uniform float4 _TestSphere;
            // direction of the light
            uniform float3 _LightDirection;
            
            // frustum -> 4 directions that maps to the 4 corners of the screen
            uniform float4x4 _CamFrustum, _CamToWorld;
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;

                // ray direction
                float3 ray : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;

                half index = v.vertex.z;
                v.vertex.z = 0;
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;

                o.ray = _CamFrustum[(int)index].xyz;

                o.ray /= abs(o.ray.z);

                o.ray = mul(_CamToWorld, o.ray);
                
                return o;
            }

            float sdSphere(float3 p, float r)
            {
                return length(p) - r;
            }
            
            float distanceField(float3 p)
            {
                float Sphere1 = sdSphere(p - _TestSphere.xyz, _TestSphere.w);

                // TODO implement the other object in the scene
                // float dist = min(Sphere1);

                return Sphere1;
            }

            float3 getNormal(float3 p)
            {
                float3 n = float3(
                    distanceField(p+OFFSET.xyy) - distanceField(p-OFFSET.xyy),
                    distanceField(p+OFFSET.yxy) - distanceField(p-OFFSET.yxy),
                    distanceField(p+OFFSET.yyx) - distanceField(p-OFFSET.yyx)
                    );

                return normalize(n);
            }
            
            fixed4 raymarching(float3 ro, float3 rd)
            {
                fixed4 result = fixed4(0.5,0.5,0.5,1);

                float dT = 0.0f; // distance traveled by ray

                for (int i = 0; i < MAX_RAYMARCH_ITERATIONS ; i++)
                {
                    if(dT > _MaxDistance)
                    {
                        // nothing is hit so we can draw the environment here
                        result = fixed4(rd, 1);
                        break;
                    }

                    // get the current position of the ray 
                    float3 p = ro + rd * dT;

                    // check the closest distance to an object
                    float d = distanceField(p);

                    // we check if there is a hit
                    if (d < DISTANCE_EPSILON)
                    {
                        //
                        float3 n = getNormal(p);
                        
                        float light = dot(-_LightDirection, n);
                        
                        result = fixed4(1,1,1,1) * light;
                        break;
                    }

                    // adding the closest distance to the dT variable
                    dT += d;    
                }
                
                return result;
                
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 rd = normalize(i.ray.xyz);
                float3 ro = _WorldSpaceCameraPos;

                fixed4 result = raymarching(ro, rd);

                return result;
            }
            ENDCG
        }
    }
}
