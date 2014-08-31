/**
* Shader to output depth for a shadowmap
*/
module dash.graphics.shaders.glsl.shadowmap;
import dash.graphics.shaders.glsl;

package:

/// Vertex Shader for inaminate objects
immutable string shadowmapVS = glslVersion ~ q{
    layout(location = 0) in vec3 vPosition_m;

    uniform mat4 worldViewProj;

    void main()
    {
        gl_Position = worldViewProj * vec4( vPosition_m, 1.0f );
    }

};

/// Vertex shader for animated objects
immutable string animatedshadowmapVS = glslVersion ~ q{
    layout(location = 0) in vec3 vPosition_m;
    //layout(location = 1) in vec2 vUV;
    //layout(location = 2) in vec3 vNormal_m;
    //layout(location = 3) in vec3 vTangent_m;
    layout(location = 4) in vec4 vBone_m;
    layout(location = 5) in vec4 vWeight_m;

    uniform mat4 worldViewProj;
    uniform mat4[100] bones;

    void main()
    {
        // Calculate vertex change from animation
        mat4 boneTransform = bones[ int(vBone_m[ 0 ]) ] * vWeight_m[ 0 ];
        boneTransform += bones[ int(vBone_m[ 1 ]) ] * vWeight_m[ 1 ];
        boneTransform += bones[ int(vBone_m[ 2 ]) ] * vWeight_m[ 2 ];
        boneTransform += bones[ int(vBone_m[ 3 ]) ] * vWeight_m[ 3 ];

        gl_Position = worldViewProj * ( boneTransform * vec4( vPosition_m, 1.0f ) );
    }
};

/// Fragment Shader, just output depth
immutable string shadowmapFS = glslVersion ~ q{
    layout(location = 0) out float fragDepth;

    void main() { }

};