#version 400

in vec3 inPosition;
in vec2 inUV;
in vec3 inNormal;
in vec3 inTangent;
in vec3 inBinormal;

out vec4 fPosition;
out vec2 fUV;

void main( void )
{
	fPosition = vec4( inPosition, 1.0f );
	gl_Position = fPosition;
	fUV = inUV;
}
