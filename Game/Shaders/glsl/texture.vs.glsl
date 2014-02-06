#version 400

// Input variables
in vec3 iPosition;
in vec2 iUV;

// Output variables
out vec2 fUV;

// Uniforms
uniform mat4 uModelViewProjection;

// Shader code
void main( void )
{
	gl_Position = uModelViewProjection * vec4( iPosition, 1.0f );

	// Store texture coordinates for pixel shader
	fUV = iUV;
}
