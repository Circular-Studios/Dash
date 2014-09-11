/**
* Lighting pass shader for Point Lights
*/
module dash.graphics.shaders.glsl.pointlight;
import dash.graphics.shaders.glsl;

package:

/// Takes a mesh representing the possible area of the light and creates a ray to each vertex
immutable string pointlightVS = glslVersion ~ q{
    layout(location = 0) in vec3 vPosition_m;
    layout(location = 1) in vec2 vUV;
    layout(location = 2) in vec3 vNormal_m;
    layout(location = 3) in vec3 vTangent_m;
    
    out vec4 fPosition_s;
    out vec3 fViewRay;
    
    //uniform mat4 world;
    uniform mat4 worldView;
    uniform mat4 worldViewProj;
    
    void main( void )
    {
        // gl_Position is like SV_Position
        fPosition_s = worldViewProj * vec4( vPosition_m, 1.0f );
        gl_Position = fPosition_s;

        fViewRay = ( worldView * vec4( vPosition_m, 1.0 ) ).xyz;

    }
};

/// Outputs diffuse and specular color from the light, using the view ray to reconstruct position and a falloff rate to attenuate
immutable string pointlightFS = glslVersion ~ q{
    struct PointLight{
        vec3 pos_v;
        vec3 color;
        float radius;
        float falloffRate;
    };
    
    in vec4 fPosition_s;
    in vec3 fViewRay;
    
    out vec4 color;
    
    uniform sampler2D diffuseTexture;
    uniform sampler2D normalTexture;
    uniform sampler2D depthTexture;
    uniform PointLight light;
    // A pair of constants for reconstructing the linear Z
    // [ (-Far * Near ) / ( Far - Near ),  Far / ( Far - Near )  ]
    uniform vec2 projectionConstants;

    // Function for decoding normals
    vec3 decode( vec2 enc )
    {
        float t = ( ( enc.x * enc.x ) + ( enc.y * enc.y ) ) / 4;
        float ti = sqrt( 1 - t );
        return vec3( ti * enc.x, ti * enc.y, -1 + t * 2 );
    }

    void main( void )
    {
        // The viewray should have interpolated across the pixels covered by the light, so we should just be able to clamp it's depth to 1
        vec3 viewRay = vec3( fViewRay.xy / fViewRay.z, 1.0f );
        vec2 UV = ( ( fPosition_s.xy / fPosition_s.w ) + 1 ) / 2;
        vec3 textureColor = texture( diffuseTexture, UV ).xyz;
        float specularIntensity = texture( diffuseTexture, UV ).w;
        vec3 normal_v = texture( normalTexture, UV ).xyz;

        // Reconstruct position from depth
        float depth = texture( depthTexture, UV ).x;
        float linearDepth = projectionConstants.x / ( projectionConstants.y - depth );
        vec3 position_v = viewRay * linearDepth;

        // calculate normalized light direction, and distance
        vec3 lightDir_v = light.pos_v - position_v;
        float distance = sqrt( dot(lightDir_v,lightDir_v) );
        lightDir_v = normalize( lightDir_v );

        // calculate exponential attenuation
        float attenuation = pow( max( 1-distance/light.radius, 0), light.falloffRate + 1.0f );

        // Diffuse lighting calculations
        float diffuseScale = clamp( dot( normal_v, lightDir_v ), 0, 1 );
        
        // Specular lighting calculations
        // Usually in these you see an "eyeDirection" variable, but in view space that is our position
        float specularScale = clamp( dot( normalize( position_v ), reflect( lightDir_v, normal_v ) ), 0, 1 );
        
        vec3 diffuse = ( diffuseScale * light.color ) * textureColor ;
        // "8" is the reflectiveness
        // textureColor.w is the shininess
        // specularIntensity is the light's contribution
        vec3 specular = ( pow( specularScale, 8 ) * light.color * specularIntensity);
        
        color = vec4((diffuse + specular ) * attenuation, 1.0f ) ;
        //color = vec4( vec3(1,0,0), 1.0f );
        
    }
};