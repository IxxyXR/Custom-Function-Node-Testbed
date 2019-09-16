Shader "Custom/InteriorMapping"
{
    Properties
    {
		_ColorFloor ("Color Floor", Color) = (1,1,1,1)
		_ColorRoof ("Color Roof", Color) = (1,1,1,1)
		_ColorWall ("Color Wall", Color) = (1,1,1,1)
		_ColorWall2 ("Color Wall 2", Color) = (1,1,1,1)
		_DistanceBetweenFloors ("Distance Between Floors", Float) = 0.25
		_DistanceBetweenWalls ("Distance Between Walls", Float) = 0.25
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
    		#pragma target 3.0
		

            //Colors
            float4 _ColorFloor;
            float4 _ColorRoof;
            float4 _ColorWall;
            float4 _ColorWall2;
    
            //Distance beteen floors
            float _DistanceBetweenFloors;
            float _DistanceBetweenWalls;
    
            //Direction vectors in local space
            static float3 upVec = float3(0, 1, 0);
            static float3 rightVec = float3(1, 0, 0);
            static float3 forwardVec = float3(0, 0, 1);

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                
                //What you have to calculate yourself
                //Faster to calculate these in the vertex function than in the surface function
                //The object view direction from the camera
                float3 objectViewDir : TEXCOORD1;
                //The local position of the fragment
                float3 objectPos: TEXCOORD2;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                UNITY_TRANSFER_FOG(o,o.vertex);
                
                //The local position of the camera
                float3 objectCameraPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1.0)).xyz;
    
                //The camera's view direction in object space						
                o.objectViewDir = v.vertex - objectCameraPos;
    
                //Save the position of the fragment in object space
                o.objectPos = v.vertex;
                return o;
            }

            //Calculate the distance between the ray start position and where it's intersecting with the plane
            //If this distance is shorter than the previous best distance, the save it and the color belonging to the wall and return it
            float4 checkIfCloser(float3 rayDir, float3 rayStartPos, float3 planePos, float3 planeNormal, float4 color, float4 colorAndDist)
            {
                //Get the distance to the plane with ray-plane intersection
                //http://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-plane-and-ray-disk-intersection
                //We are always intersecting with the plane so we dont need to spend time checking that			
                float t = dot(planePos - rayStartPos, planeNormal) / dot(planeNormal, rayDir);
    
                //At what position is the ray intersecting with the plane - use this if you need uv coordinates
                //float3 intersectPos = rayStartPos + rayDir * t;
    
                //If the distance is closer to the camera than the previous best distance
                if (t < colorAndDist.w)
                {
                    //This distance is now the best distance
                    colorAndDist.w = t;
    
                    //Set the color that belongs to this wall
                    colorAndDist.rgb = color;
                }
    
                return colorAndDist;
            }
    
    
            fixed4 frag (v2f i) : SV_Target
            {
            
               fixed4 col;
            
                //The view direction of the camera to this fragment in local space
                float3 rayDir = normalize(i.objectViewDir);
    
                //The local position of this fragment
                float3 rayStartPos = i.objectPos;
    
                //Important to start inside the house or we will display one of the outer walls
                rayStartPos += rayDir * 0.0001;
    
    
                //Init the loop with a float4 to make it easier to return from a function
                //colorAndDist.rgb is the color that will be displayed
                //colorAndDist.w is the shortest distance to a wall so far so we can find which wall is the closest
                float4 colorAndDist = float4(float3(1,1,1), 100000000.0);
    
    
                //Intersection 1: Wall / roof (y)
                //Camera is looking up if the dot product is > 0 = Roof
                if (dot(upVec, rayDir) > 0)
                {				
                    //The local position of the roof
                    float3 wallPos = (ceil(rayStartPos.y / _DistanceBetweenFloors) * _DistanceBetweenFloors) * upVec;
    
                    //Check if the roof is intersecting with the ray, if so set the color and the distance to the roof and return it
                    colorAndDist = checkIfCloser(rayDir, rayStartPos, wallPos, upVec, _ColorRoof, colorAndDist);
                }
                //Floor
                else
                {
                    float3 wallPos = ((ceil(rayStartPos.y / _DistanceBetweenFloors) - 1.0) * _DistanceBetweenFloors) * upVec;
    
                    colorAndDist = checkIfCloser(rayDir, rayStartPos, wallPos, upVec * -1, _ColorFloor, colorAndDist);
                }
                
    
                //Intersection 2: Right wall (x)
                if (dot(rightVec, rayDir) > 0)
                {
                    float3 wallPos = (ceil(rayStartPos.x / _DistanceBetweenWalls) * _DistanceBetweenWalls) * rightVec;
    
                    colorAndDist = checkIfCloser(rayDir, rayStartPos, wallPos, rightVec, _ColorWall, colorAndDist);
                }
                else
                {
                    float3 wallPos = ((ceil(rayStartPos.x / _DistanceBetweenWalls) - 1.0) * _DistanceBetweenWalls) * rightVec;
    
                    colorAndDist = checkIfCloser(rayDir, rayStartPos, wallPos, rightVec * -1, _ColorWall, colorAndDist);
                }
    
    
                //Intersection 3: Forward wall (z)
                if (dot(forwardVec, rayDir) > 0)
                {
                    float3 wallPos = (ceil(rayStartPos.z / _DistanceBetweenWalls) * _DistanceBetweenWalls) * forwardVec;
    
                    colorAndDist = checkIfCloser(rayDir, rayStartPos, wallPos, forwardVec, _ColorWall2, colorAndDist);
                }
                else
                {
                    float3 wallPos = ((ceil(rayStartPos.z / _DistanceBetweenWalls) - 1.0) * _DistanceBetweenWalls) * forwardVec;
    
                    colorAndDist = checkIfCloser(rayDir, rayStartPos, wallPos, forwardVec * -1, _ColorWall2, colorAndDist);
                }
    
                
                //Output
                col = colorAndDist;
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
