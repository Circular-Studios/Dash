#version 400

in vec4 fPosition;
in vec2 fUV;

uniform sampler2D diffuseTexture;
uniform sampler2D normalTexture;
uniform sampler2D depthTexture;

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
	vec4 textureColor = texture( diffuseTexture, fUV );
	vec3 normal = texture( normalTexture, fUV ).xyz;
	//normal = vec4( decode( normal.xy ), 1.0f);

	// temp vars until we get lights in
	vec3 lightDirection = vec3( 0.0f, 1.0f, -1.0f );
	vec4 diffuseColor = vec4( 1.0f, 1.0f, 1.0f, 1.0f );

	float diffuseIntensity = clamp( dot( normal, -lightDirection ), 0, 1 );
	color = vec4( normal, 1.0f );
}
