/**
* Geometry pass shader for standard meshes
*/
module dash.graphics.shaders.glsl.geometry;
import dash.graphics.shaders.glsl;

package:

/// Standard mesh vertex shader, transforms position to screen space and normals/tangents to view space
immutable string geometryVS = glslVersion ~ q{
    layout(location = 0) in vec3 vPosition_m;
    layout(location = 1) in vec2 vUV;
    layout(location = 2) in vec3 vNormal_m;
    layout(location = 3) in vec3 vTangent_m;

    out vec4 fPosition_s;
    out vec3 fNormal_v;
    out vec2 fUV;
    out vec3 fTangent_v;
    flat out uint fObjectId;

    uniform mat4 worldView;
    uniform mat4 worldViewProj;
    uniform uint objectId;

    void main( void )
    {
        // gl_Position is like SV_Position
        fPosition_s = worldViewProj * vec4( vPosition_m, 1.0f );
        gl_Position = fPosition_s;
        fUV = vUV;

        fNormal_v = ( worldView * vec4( vNormal_m, 0.0f ) ).xyz;
        fTangent_v =  ( worldView * vec4( vTangent_m, 0.0f ) ).xyz;
        fObjectId = objectId;
    }
};

/// Saves diffuse, specular, mappedNormals (encoded to spheremapped XY), and object ID to appropriate FBO textures
immutable string geometryFS = glslVersion ~ q{
    in vec4 fPosition_s;
    in vec3 fNormal_v;
    in vec2 fUV;
    in vec3 fTangent_v;
    flat in uint fObjectId;

    layout( location = 0 ) out vec4 color;
    layout( location = 1 ) out vec4 normal_v;

    uniform sampler2D diffuseTexture;
    uniform sampler2D normalTexture;
    uniform sampler2D specularTexture;

    vec2 encode( vec3 normal )
    {
        float t = sqrt( 2 / ( 1 - normal.z ) );
        return normal.xy * t;
    }

    vec3 calculateMappedNormal()
    {
        vec3 normal = normalize( fNormal_v );
        vec3 tangent = normalize( fTangent_v );
        //Use Gramm-Schmidt process to orthogonalize the two
        tangent = normalize( tangent - dot( tangent, normal ) * normal );
        vec3 bitangent = -cross( tangent, normal );
        vec3 normalMap = ((texture( normalTexture, fUV ).xyz) * 2) - 1;
        mat3 TBN = mat3( tangent, bitangent, normal );
        return normalize( TBN * normalMap );
    }

    void main( void )
    {
        color = texture( diffuseTexture, fUV );
        // specular intensity
        vec3 specularSample = texture( specularTexture, fUV ).xyz;
        color.w = ( specularSample.x + specularSample.y + specularSample.z ) / 3;
        normal_v = vec4( calculateMappedNormal(), float(fObjectId) );
    }
};

