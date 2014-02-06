#version 400

// In vars
in vec2 fUV;

// Uniform vars
uniform sampler2D uShaderTexture;

// Shader code
void main( void )
{
	vec4 color;
	// Sample pixel color from texture using the sampler
	color = texture( uShaderTexture, fUV );

	gl_FragColor = color;
}
