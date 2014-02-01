#version 400

in vec3 inPosition;
in vec2 inUV;
in vec3 inNormal;
in vec3 inTangent;
in vec3 inBinormal; 

out vec3 fPosition;
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
	fPosition = worldViewProj * inPosition;
	gl_Position = fPosition;
	fNormal = normalize( world * inNormal );
	fUV = inUV;
	fTangent = normalize( world * inTangent );
	fBinormal = normalize( world * inBinormal );
}
