#version 400

layout(location = 0) in vec3 inPosition;
layout(location = 1) in vec2 inUV;
layout(location = 2) in vec3 inNormal;
layout(location = 3) in vec3 inTangent;
layout(location = 4) in vec3 inBinormal; 

out vec4 fPosition;
out vec3 fNormal;
out vec2 fUV;
out vec3 fTangent;
out vec3 fBinormal;

uniform mat4 world;
uniform mat4 worldViewProj;

void main( void )
{
	// gl_Position is like SV_Position
	fPosition = worldViewProj * vec4( inPosition, 1.0f );
	gl_Position = fPosition;
	fNormal = normalize( world * vec4( inNormal, 1.0f ) ).xyz;
	fUV = inUV;
	fTangent = normalize( world * vec4( inTangent, 1.0f ) ).xyz;
	fBinormal = normalize( world * vec4( inBinormal, 1.0f ) ).xyz;
}
