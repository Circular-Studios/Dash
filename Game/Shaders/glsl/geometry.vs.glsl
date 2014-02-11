#version 400

layout(location = 0) in vec3 inPosition;
layout(location = 1) in vec2 inUV;
layout(location = 2) in vec3 inNormal;
layout(location = 3) in vec4 inTangent;

out vec4 fPosition;
out vec3 fNormal;
out vec2 fUV;
out vec3 fTangent;
out vec3 fBinormal;

uniform mat4 world;
uniform mat4 worldView;
uniform mat4 worldViewProj;

void main( void )
{
	// gl_Position is like SV_Position
	fPosition = worldViewProj * vec4( inPosition, 1.0f );
	gl_Position = fPosition;

	vec3 binormal = cross( inNormal, inTangent.xyz ) * inTangent.w;

	mat3 wv3x3 = mat3( worldView );
	vec3 normal_cameraspace = wv3x3 * inNormal;
	vec3 tangent_cameraspace = wv3x3 * inTangent.xyz;
	vec3 binormal_cameraspace = wv3x3 * binormal;
	fNormal = normal_cameraspace;//normalize( world * vec4( inNormal, 1.0f ) ).xyz;
	fUV = inUV;
	fTangent = tangent_cameraspace;//normalize( world * vec4( inTangent.xyz, 1.0f ) ).xyz;
	fBinormal = binormal_cameraspace;//normalize( world * vec4( binormal, 1.0f ) ).xyz;
}
