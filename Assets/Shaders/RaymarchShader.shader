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
            #include "DistanceFunctions.cginc"

            #define MAX_RAYMARCH_ITERATIONS 256
            #define DISTANCE_EPSILON 0.01f
            #define OFFSET (float2(0.001,0))
            

            // parameters
            sampler2D _MainTex;
            // check if there are meshes in scene
            uniform sampler2D _CameraDepthTexture;
            // maximum distance the ray is allowed to travel
            uniform float _MaxDistance;
            // shapes for testing
            uniform float4 _TestSphere;
            uniform float4 _TestBox;
            // direction of the light
            uniform float3 _LightDirection;
            // frustum -> 4 directions that maps to the 4 corners of the screen
            uniform float4x4 _CamFrustum, _CamToWorld;
            // main color of the shader
            uniform fixed4 _MainColor;
            
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
            
            float distanceField(float3 p)
            {
                // float modX = pMod1(p.x, 7);
                // float modY = pMod1(p.y, 7);
                // float modZ = pMod1(p.z, 7);
                
                float Sphere1 = sdSphere(p - _TestSphere.xyz, _TestSphere.w);

                float Box1 = sdBox(p-_TestBox.xyz, _TestBox.w);
                // TODO implement the other object in the scene
                // float dist = min(Sphere1);

                return opS(Sphere1, Box1);
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
            
            fixed4 raymarching(float3 ro, float3 rd, float depth)
            {
                fixed4 result = fixed4(rd,0);

                float dT = 0.0f; // distance traveled by ray

                for (int i = 0; i < MAX_RAYMARCH_ITERATIONS ; i++)
                {
                    if(dT > _MaxDistance || dT >= depth)
                    {
                        // nothing is hit so we can draw the environment here
                        result = fixed4(rd, 0);
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
                        
                        result = fixed4(_MainColor.xyz * light, 1);
                        break;
                    }

                    // adding the closest distance to the dT variable
                    dT += d;    
                }
                
                return result;
                
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // to check the meshes in scene
                float depth = LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv).r);
                depth *= length(i.ray);
                
                // color of the viewer
                float3 col = tex2D(_MainTex, i.uv);

                // ray info
                float3 rd = normalize(i.ray.xyz);
                float3 ro = _WorldSpaceCameraPos;

                // computing the ray
                fixed4 result = raymarching(ro, rd, depth);

                // check if we use the ray color or the scene color
                                 // scene view           // hit value
                float3 hitCheck = (col * (1.0-result.w)) + (result.xyz * result.w);

                // return the result
                return fixed4(hitCheck, 1.0);
            }
            ENDCG
        }
    }
}
