module graphics.shaders.glsl.directionallight;

package:


immutable string directionallightVS = q{
    #version 400

    layout(location = 0) in vec3 vPosition_s;
    layout(location = 1) in vec2 vUV;

    uniform mat4 invProj;

    out vec4 fPosition_s;
    out vec2 fUV;
    out vec3 fViewRay;

    void main( void )
    {
        fPosition_s = vec4( vPosition_s, 1.0f );
        gl_Position = fPosition_s;

        vec3 position_v = mul( invProj, vPosition_s );
        // This is the ray clamped to depth 1, and it'll just be moved & interpolated in the XY
        fViewRay = vec3( position_v.xy / position_v.z, 1.0f );
        fUV = vUV;
    }
};

immutable string directionallightFS = q{
    #version 400

    struct DirectionalLight
    {
        vec3 color;
        vec3 direction;
    };

    in vec4 fPosition;
    in vec2 fUV;
    in vec3 fViewRay;

    // this diffuse should be set to the geometry output
    uniform sampler2D diffuseTexture;
    uniform sampler2D normalTexture;
    uniform sampler2D depthTexture;
    uniform DirectionalLight light;
    // A pair of constants for reconstructing the linear Z
    // [ (-Far * Near ) / ( Far - Near ),  Far / ( Far - Near )  ]
    uniform vec2 projectionConstant;
    uniform mat4 invProj;

    // https://stackoverflow.com/questions/9222217/how-does-the-fragment-shader-know-what-variable-to-use-for-the-color-of-a-pixel
    out vec4 color;

    vec3 decode( vec2 enc )
    {
        float t = ( ( enc.x * enc.x ) + ( enc.y * enc.y ) ) / 4;
        float ti = sqrt( 1 - t );
        return vec3( ti * enc.x, ti * enc.y, -1 + t * 2 );
    }

    void main( void )
    {
        vec3 textureColor = texture( diffuseTexture, fUV ).xyz;
        float specularIntensity = texture( diffuseTexture, fUV ).w;
        vec3 normal_v = texture( normalTexture, fUV ).xyz;
        vec3 lightDir_v = normalize( light.direction );

        // Reconstruct position from Depth
        float depth = texture( depthTexture, fUV ).x;
        float linearDepth = projectionConstant.x / ( depth - projectionConstant.y );
        vec3 position_v = viewRay * linearDepth;


        // Diffuse lighting calculations
        float diffuseScale = clamp( dot( normal, -lightDir ), 0, 1 );

        // Specular lighting calculations
        // Usually in these you see an "eyeDirection" variable, but in view space that is our position
        float specularScale = clamp( dot( position_v, reflect( -lightDir, normal ) ), 0, 1 );

        vec3 diffuse = ( diffuseScale * light.color ) * textureColor;
        // "8" is the reflectiveness
        // textureColor.w is the shininess
        // specularIntensity is the light's contribution
        vec3 specular = ( pow( specularScale, 8 ) * light.color * specularIntensity);
        color = vec4( ( diffuse + specular ), 1.0f );
    }
};