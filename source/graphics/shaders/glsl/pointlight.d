module graphics.shaders.glsl.pointlight;

package:

immutable string pointlightVS = q{
#version 400
    
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

immutable string pointlightFS = q{
#version 400

    struct PointLight{
        vec3 pos_v;
        vec3 color;
        float radius;
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

    void main( void )
    {
        // The viewray should have interpolated across the pixels covered by the light, so we should just be able to clamp it's depth to 1
        vec3 viewRay = vec3( fViewRay.xy / fViewRay.z, 1.0f );
        vec2 UV = ( ( fPosition_s.xy / fPosition_s.w ) + 1 ) / 2;
        vec3 textureColor = texture( diffuseTexture, UV ).xyz;
        float specularIntensity = texture( diffuseTexture, UV ).w;
        vec3 normal_v = normalize(texture( normalTexture, UV ).xyz);

        // Reconstruct position from depth
        float depth = texture( depthTexture, UV ).x;
        float linearDepth = projectionConstants.x / ( projectionConstants.y - depth );
        vec3 position_v = viewRay * linearDepth;

        // calculate normalized light direction, and distance
        vec3 lightDir_v = light.pos_v - position_v;
        float distance = sqrt( dot(lightDir_v,lightDir_v) );
        lightDir_v = normalize( lightDir_v );

        // attenuation = 1 / ( constant + linear*d + quadratic*d^2 )
        // .005 is the cutoff, 10 is the intensity just hard coded for now
        float attenuation = max( light.radius-distance, 0) / light.radius; //( 1 + 2/light.radius*distance + 1/(light.radius*light.radius)*(distance*distance) );
        //attenuation = pow(max(0.0, 1.0 - (distance / radius)), f + 1.0);
        //attenuation = (attenuation - .005) / (1 - .005);
        //attenuation = max(attenuation, 0);

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