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
// Upgrade NOTE: excluded shader from DX11, OpenGL ES 2.0 because it uses unsized arrays
#pragma exclude_renderers d3d11 gles
            #pragma vertex vert
            #pragma fragment frag

            // adding a target
            #pragma target 3.0

            #ifndef RAYMARCHER_SHADER
            #define RAYMARCHER_SHADER
            
            #include "UnityCG.cginc"
            #include "Primitives.cginc"
            #include "MengerSponge.cginc"
            #include "Mandelbulb.cginc"

            #define MAX_RAYMARCH_ITERATIONS 256
            #define DISTANCE_EPSILON 0.01f
            #define OFFSET (float2(0.001,0))
            

            // parameters

            // main texture
            sampler2D _MainTex;
            // frustum -> 4 directions that maps to the 4 corners of the screen
            uniform float4x4 _CamFrustum, _CamToWorld;
            // check if there are meshes in scene
            uniform sampler2D _CameraDepthTexture;
            // maximum distance the ray is allowed to travel
            uniform float _MaxDistance;

            #define MENGER_SPONGES_LIMIT 5

            int _MengerSpongesLimit;
            
            float4 _MengerSpongesVectors[MENGER_SPONGES_LIMIT];
            float _MengerSpongesScales[MENGER_SPONGES_LIMIT];
            int _MengerSpongesRep[MENGER_SPONGES_LIMIT];

            // to repeat the shapes
            uniform float _ModRepeatX;
            uniform float _ModRepeatY;
            uniform float _ModRepeatZ;

            // to repeat the shapes
            uniform bool _SwitchRepeatX;
            uniform bool _SwitchRepeatY;
            uniform bool _SwitchRepeatZ;
            
            // main color of the shapes
            uniform fixed4 _MainColor;
            
            // direction of the light
            uniform float3 _LightDirection;
            // color of the light
            uniform float3 _LightColor;
            // intensity of the light
            uniform float _LightIntensity; 
           
            // distance of shadow
            uniform float2 _ShadowDistance;
            // instensity of shadow
            uniform float _ShadowIntensity;
            // penumbra coefficient for the shadow
            uniform float _ShadowPenumbra;

            // ambient occlusion
            uniform int _MaxIterations;
            uniform float _Accuracy;
            uniform  float _AoStepSize;
            uniform  float _AoIterations;
            uniform  float _AoIntensity;
            
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
                // check if we repeat the shapes
                if(_SwitchRepeatX)
                {
                    float modX = modAxis(p.x, _ModRepeatX);
                }
                if(_SwitchRepeatY)
                {
                    float modY = modAxis(p.y, _ModRepeatY);
                }
                if(_SwitchRepeatZ)
                {
                    float modY = modAxis(p.z, _ModRepeatZ);
                }

                float2 closestPoint = 999999;

                for(int i = 0; i < _MengerSpongesLimit; i++)
                {
                    float2 current = mengerSpongeMap(p - _MengerSpongesVectors[i].xyz,
                                    _MengerSpongesScales[i],
                                    _MengerSpongesVectors[i].w,
                                    _MengerSpongesRep[i]);
                    
                    closestPoint = min(closestPoint, current);
                }

                closestPoint = mandelbulbMap(p - _MengerSpongesVectors[0], 6);
                
                return closestPoint.x;
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

            float hardShadow(float3 ro, float3 rd, float mint, float maxt, float k)
            {
                float result = 1.0;
                
                for(float t = mint ; t < maxt;)
                {
                    float h = distanceField(ro+rd*t);

                    if (h < 0.001)
                    {
                        return 0.0;
                    }

                    result = min(result, k*h/t);
                    
                    t += h;
                }

                return result;
            }

            float ambientOcclusion(float3 p, float3 n)
            {
                float ao = 0.0;
                float dist;

                for (int i = 1; i <= _AoIterations; i++)
                {
                    dist = _AoStepSize * i;
                    ao += max(0.0, (dist - distanceField(p + n * dist)) / dist);
                }

                return (1.0 - ao * _AoIntensity);
            }
            
            float3 shading(float3 p, float3 n)
            {
                // result of shading
                float3 result;
                
                // main color
                float3 color = _MainColor.rgb;
                
                // directional light
                float3 light = ((_LightColor * dot(-_LightDirection, n) * 0.5 + 0.5 ) * _LightIntensity);

                // hard shadow
                float shadow = hardShadow(p, -_LightDirection, _ShadowDistance.x, _ShadowDistance.y, _ShadowPenumbra) * 0.5 + 0.5;

                // ambient occlusion
                float ao = ambientOcclusion( p, n);
                
                shadow = max(0.0, pow(shadow, _ShadowIntensity));
                
                result = color * light * shadow * ao;
                
                return result;
            }
            
            fixed4 raymarching(float3 ro, float3 rd, float depth)
            {
                fixed4 result = fixed4(rd,0);

                float dT = 0.0f; // distance traveled by ray

                for (int i = 0; i < _MaxIterations ; i++)
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
                    if (d < _Accuracy)
                    {
                        // normal
                        float3 n = getNormal(p);

                        // shading
                        float3 s = shading(p, n);
                        
                        return  fixed4(s, 1);
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

            #endif
            ENDCG
        }
    }
}
