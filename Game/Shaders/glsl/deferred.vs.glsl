#version 400

in vec3 inPosition;
in vec2 inUV;
in vec3 inNormal;
in vec3 inTangent;
in vec3 inBinormal; 

out vec4 fPosition;
out vec3 fNormal;
out vec2 fUV;
out vec3 fTangent;
out vec3 fBinormal;

uniform mat4 world;
uniform mat4 worldViewProj;
uniform int windowWidth;
uniform int windowHeight;

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
