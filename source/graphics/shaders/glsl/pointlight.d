module graphics.shaders.glsl.pointlight;

package:

immutable string pointlightVS = q{
#version 400
    
    layout(location = 0) in vec3 vPosition_m;
    layout(location = 1) in vec2 vUV;
    layout(location = 2) in vec3 vNormal_m;
    layout(location = 3) in vec3 vTangent_m;
    
    out vec4 fPosition_s;
    //out vec3 fNormal_w;
    out vec2 fUV;
    //out vec3 fTangent_w;
    //out vec3 fBitangent_w;
    
    //uniform mat4 world;
    //uniform mat4 worldView;
    uniform mat4 worldViewProj;
    
    void main( void )
    {
        // gl_Position is like SV_Position
        fPosition_s = worldViewProj * vec4( vPosition_m, 1.0f );
        gl_Position = fPosition_s;
        //fUV = vUV;
        
        //fNormal_w = ( world * vec4( vNormal_m, 0.0f ) ).xyz;
        //fTangent_w =  ( world * vec4( vTangent_m, 0.0f ) ).xyz;
    }
};

immutable string pointlightFS = q{
#version 400

    struct PointLight{
        vec3 pos_w;
        vec3 color;
        float radius;
    };
    
    in vec4 fPosition_s;
    //in vec3 fNormal_w;
    //in vec2 fUV;
    //in vec3 fTangent_w;
    
    out vec4 color;
    
    uniform sampler2D diffuseTexture;
    uniform sampler2D normalTexture;
    uniform sampler2D depthTexture;
    uniform PointLight light;
    uniform vec3 eyePosition_w;
    uniform mat4 invViewProj;

    void main( void )
    {
        vec2 position_s = fPosition_s.xy / fPosition_s.w;
        vec2 UV = ( position_s + 1 ) / 2;
        vec3 textureColor = texture( diffuseTexture, UV ).xyz;
        float specularIntensity = texture( diffuseTexture, UV ).w;
        vec3 normal = normalize(texture( normalTexture, UV ).xyz);

        // pixelPosition is essentially 3D screen space coordinates - x, y, z of the screen
        vec3 pixelPosition_s = vec3( position_s, (texture( depthTexture, UV ).x * 2 - 1));
        // Multiplying screen space coordinates by the inverse viewProjection matrix gives you world coordinates
        vec4 pixelPosition_w = ( invViewProj * vec4( pixelPosition_s, 1.0f ) );
        pixelPosition_w /= pixelPosition_w.w;

        // calculate normalized light direction, distance
        vec3 lightDir = light.pos_w - pixelPosition_w.xyz;
        float distance = sqrt( dot(lightDir,lightDir) );
        lightDir = normalize( lightDir );

        // attenuation = 1 / ( constant + linear*d + quadratic*d^2 )
        // .005 is the cutoff, 10 is the intensity just hard coded for now
        float attenuation = max( light.radius-distance, 0) / light.radius; //( 1 + 2/light.radius*distance + 1/(light.radius*light.radius)*(distance*distance) );
        //attenuation = (attenuation - .005) / (1 - .005);
        //attenuation = max(attenuation, 0);

        // Diffuse lighting calculations
        float diffuseScale = clamp( dot( normal, lightDir ), 0, 1 );
        
        // Specular lighting calculations
        vec3 eyeDirection = normalize( pixelPosition_w.xyz - eyePosition_w );
        float specularScale = clamp( dot( eyeDirection, normalize(reflect( lightDir, normal )) ), 0, 1 );
        
        vec3 diffuse = ( diffuseScale * light.color ) * textureColor ;
        // "8" is the reflectiveness
        // textureColor.w is the shininess
        // specularIntensity is the light's contribution
        vec3 specular = ( pow( specularScale, 8 ) * light.color * specularIntensity);
        color = vec4( (diffuse + specular)* attenuation, 1.0f ) ;
        //color = vec4( vec3(1,0,0), 1.0f );
        
    }
};