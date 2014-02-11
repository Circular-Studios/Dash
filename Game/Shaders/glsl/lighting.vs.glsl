#version 400

layout(location = 0) in vec3 vPosition_s;
layout(location = 1) in vec2 vUV;

out vec4 fPosition_s;
out vec2 fUV;

void main( void )
{
	fPosition_s = vec4( vPosition_s, 1.0f );
	gl_Position = fPosition_s;
	fUV = vUV;
}
