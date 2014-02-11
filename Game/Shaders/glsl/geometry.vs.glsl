#version 400

layout(location = 0) in vec3 vPosition_m;
layout(location = 1) in vec2 vUV;
layout(location = 2) in vec3 vNormal_m;
layout(location = 3) in vec3 vTangent_m;

out vec4 fPosition_s;
out vec3 fNormal_w;
out vec2 fUV;
out vec3 fTangent_w;

uniform mat4 world;
uniform mat4 worldView;
uniform mat4 worldViewProj;

void main( void )
{
	// gl_Position is like SV_Position
	fPosition_s = worldViewProj * vec4( vPosition_m, 1.0f );
	gl_Position = fPosition_s;
	fUV = vUV;

	fNormal_w = ( world * vec4( vNormal_m, 0.0f ) ).xyz;
	fTangent_w =  ( world * vec4( vTangent_m, 0.0f ) ).xyz;
}
