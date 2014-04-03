module graphics.shaders.glsl.geometry;

package:

immutable string geometryVS = q{
    #version 400

    layout(location = 0) in vec3 vPosition_m;
    layout(location = 1) in vec2 vUV;
    layout(location = 2) in vec3 vNormal_m;
    layout(location = 3) in vec3 vTangent_m;

    out vec4 fPosition_s;
    out vec3 fNormal_v;
    out vec2 fUV;
    out vec3 fTangent_v;

    uniform mat4 world;
    uniform mat4 worldView;
    uniform mat4 worldViewProj;

    void main( void )
    {
        // gl_Position is like SV_Position
        fPosition_s = worldViewProj * vec4( vPosition_m, 1.0f );
        gl_Position = fPosition_s;
        fUV = vUV;

        fNormal_v = ( worldView * vec4( vNormal_m, 0.0f ) ).xyz;
        fTangent_v =  ( worldView * vec4( vTangent_m, 0.0f ) ).xyz;
    }
};

immutable string geometryFS = q{
    #version 400

    in vec4 fPosition_s;
    in vec3 fNormal_v;
    in vec2 fUV;
    in vec3 fTangent_v;

    layout( location = 0 ) out vec4 color;
    layout( location = 1 ) out vec4 normal_v;

    uniform sampler2D diffuseTexture;
    uniform sampler2D normalTexture;
    uniform sampler2D specularTexture;

    vec2 encode( vec3 normal )
    {
        float t = sqrt( 2 / 1 - normal.z );
        return normal.xy * t;
    }

    vec3 calculateMappedNormal()
    {
        vec3 normal = normalize( fNormal_v );
        vec3 tangent = normalize( fTangent_v );
        //Use Gramm-Schmidt process to orthogonalize the two
        tangent = normalize( tangent - dot( tangent, normal ) * normal );
        vec3 bitangent = cross( tangent, normal );
        vec3 normalMap = ((texture( normalTexture, fUV ).xyz) * 2) - 1;
        mat3 TBN = mat3( tangent, bitangent, normal );
        return normalize( TBN * normalMap );
    }

    void main( void )
    {
        color = texture( diffuseTexture, fUV );
        // specular exponent
        vec3 specularSample = texture( specularTexture, fUV ).xyz;
        color.w = ( specularSample.x + specularSample.y + specularSample.z ) / 3;
        normal_v = vec4( calculateMappedNormal(), 1.0f );
    }
};

