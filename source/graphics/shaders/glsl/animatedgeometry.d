module graphics.shaders.glsl.animatedgeometry;

package:

///
/// Animated Geometry Shader
///
immutable string animatedGeometryVS = q{
    #version 400

    layout(location = 0) in vec3 vPosition_m;
    layout(location = 1) in vec2 vUV;
    layout(location = 2) in vec3 vNormal_m;
    layout(location = 3) in vec4 vTangent_m;
    layout(location = 4) in vec4 vBone_m;
    layout(location = 5) in vec4 vWeight_m;

    out vec4 fPosition_s;
    out vec3 fNormal_v;
    out vec2 fUV;
    out vec3 fTangent_v;
    flat out float fBitangentDirection;

    uniform mat4 world;
    uniform mat4 worldView;
    uniform mat4 worldViewProj;

    uniform mat4[100] bones;

    void main( void )
    {
        // Calculate vertex change from animation
        mat4 boneTransform = bones[ int(vBone_m[ 0 ]) ] * vWeight_m[ 0 ];
        boneTransform += bones[ int(vBone_m[ 1 ]) ] * vWeight_m[ 1 ];
        boneTransform += bones[ int(vBone_m[ 2 ]) ] * vWeight_m[ 2 ];
        boneTransform += bones[ int(vBone_m[ 3 ]) ] * vWeight_m[ 3 ];

        // gl_Position is like SV_Position
        fPosition_s = worldViewProj * ( boneTransform * vec4( vPosition_m, 1.0f ) );
        gl_Position = fPosition_s;
        fUV = vUV;

        fNormal_v = ( worldView * boneTransform * vec4( vNormal_m, 0.0f ) ).xyz;
        fTangent_v =  ( worldView * boneTransform * vec4( vTangent_m.xyz, 0.0f ) ).xyz;
        fBitangentDirection = vTangent_m.w;
    }
};