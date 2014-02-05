#version 400

in vec4 fPosition;
in vec2 fUV;

uniform sampler2D diffuseTexture;
uniform sampler2D normalTexture;
uniform sampler2D depthTexture;

// https://stackoverflow.com/questions/9222217/how-does-the-fragment-shader-know-what-variable-to-use-for-the-color-of-a-pixel
out vec4 color;

void main( void )
{
	vec4 textureColor = texture( diffuseTexture, fUV );
	vec4 normal = texture( normalTexture, fUV );

	// temp vars until we get lights in
	vec4 lightDirection = vec4( -1.0f, -1.0f, 1.0f, 1.0f );
	vec4 diffuseColor = vec4( 0.1f, 0.1f, 0.1f, 1.0f );

	float diffuseIntensity = clamp( dot( normal, normalize(-lightDirection) ), 0.0f, 1.0f );
	color = clamp( diffuseIntensity * diffuseColor, 0.0f, 1.0f );
	color = color * textureColor;

}
