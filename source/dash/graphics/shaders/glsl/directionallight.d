/**
* Lighting pass shader for Directional Lights
*/
module dash.graphics.shaders.glsl.directionallight;
import dash.graphics.shaders.glsl;

package:

/// Takes in a clip-space quad and creates a ray from camera to each vertex, which is interpolated during pass-through
immutable string directionallightVS = glslVersion ~ q{
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

        vec3 position_v = ( invProj * vec4( vPosition_s, 1.0f ) ).xyz;
        // This is the ray clamped to depth 1, and it'll just be moved & interpolated in the XY
        fViewRay = vec3( position_v.xy / position_v.z, 1.0f );
        fUV = vUV;
    }
};

/// Calculates diffuse and specular lights from the full-screen directional light, 
/// using the view ray to reconstruct pixel position
immutable string directionallightFS = glslVersion ~ q{
    struct DirectionalLight
    {
        vec3 color;
        vec3 direction;
        float shadowless;
    };

    in vec4 fPosition_s;
    in vec2 fUV;
    in vec3 fViewRay;

    // g-buffer outputs
    uniform sampler2D diffuseTexture;
    uniform sampler2D normalTexture;
    uniform sampler2D depthTexture;

    // shadow map values
    uniform sampler2D shadowMap;
    uniform mat4 lightProjView;
    uniform mat4 cameraView;

    uniform DirectionalLight light;

    // A pair of constants for reconstructing the linear Z
    // [ (-Far * Near ) / ( Far - Near ),  Far / ( Far - Near )  ]
    uniform vec2 projectionConstants;

    // https://stackoverflow.com/questions/9222217/how-does-the-fragment-shader-know-what-variable-to-use-for-the-color-of-a-pixel
    layout( location = 0 ) out vec4 color;

    // Function for decoding normals
    vec3 decode( vec2 enc )
    {
        float t = ( ( enc.x * enc.x ) + ( enc.y * enc.y ) ) / 4;
        float ti = sqrt( 1 - t );
        return vec3( ti * enc.x, ti * enc.y, -1 + t * 2 );
    }

    float shadowValue(vec3 pos)
    {
        mat4 toShadowMap_s = lightProjView * inverse(cameraView);
        vec4 lightSpacePos = toShadowMap_s * vec4( pos, 1 );
        lightSpacePos = lightSpacePos / lightSpacePos.w;

        vec2 shadowCoords = (lightSpacePos.xy * 0.5) + vec2( 0.5, 0.5 );

        float depthValue = texture( shadowMap, shadowCoords ).x -  0.0001;

        return float( (lightSpacePos.z * .5 + .5 ) < depthValue );
    }

    void main( void )
    {
        vec3 textureColor = texture( diffuseTexture, fUV ).xyz;
        float specularIntensity = texture( diffuseTexture, fUV ).w;
        vec3 normal_v = texture( normalTexture, fUV ).xyz;
        vec3 lightDir_v = -normalize( light.direction );

        // Reconstruct position from Depth
        float depth = texture( depthTexture, fUV ).x;
        float linearDepth = projectionConstants.x / ( projectionConstants.y - depth );
        vec3 position_v = fViewRay * linearDepth;


        // Diffuse lighting calculations
        float diffuseScale = clamp( dot( normal_v, lightDir_v ), 0, 1 );

        // Specular lighting calculations
        // Usually in these you see an "eyeDirection" variable, but in view space that is our position
        float specularScale = clamp( dot( normalize( position_v ), reflect( lightDir_v, normal_v ) ), 0, 1 );

        vec3 diffuse = ( diffuseScale * light.color ) * textureColor;
        // "8" is the reflectiveness
        // textureColor.w is the shininess
        // specularIntensity is the light's contribution
        vec3 specular = ( pow( specularScale, 8 ) * light.color * specularIntensity);

        color = max( light.shadowless , shadowValue(position_v) ) * vec4( ( diffuse + specular ), 1.0f );
    }
};