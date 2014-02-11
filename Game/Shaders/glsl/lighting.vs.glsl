#version 400

layout(location = 0) in vec3 inPosition;
layout(location = 1) in vec2 inUV;
layout(location = 2) in vec3 inNormal;
layout(location = 3) in vec4 inTangent;

out vec4 fPosition;
out vec2 fUV;

void main( void )
{
	fPosition = vec4( inPosition, 1.0f );
	gl_Position = fPosition;
	fUV = inUV;
}
