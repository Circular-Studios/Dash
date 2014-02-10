#version 400

in vec4 fPosition;
in vec3 fNormal;
in vec2 fUV;
in vec3 fTangent;
in vec3 fBinormal;

layout( location = 0 ) out vec4 color;
layout( location = 1 ) out vec4 normal;

uniform sampler2D diffuseTexture;
uniform sampler2D normalTexture;

vec2 encode( vec3 normal )
{
	float t = sqrt( 2 / 1 - normal.z );
	return normal.xy * t;
}

void main( void )
{
	vec4 textureColor = texture( diffuseTexture, fUV );
	color = textureColor;
	vec4 normalMap = texture( normalTexture, fUV );
	
	normal = vec4( encode( normalMap.xyz ), 1.0f, 1.0f ); //vec4( normalize( fNormal + ( normalMap.x * fTangent ) + ( normalMap.y * fBinormal ) ), 1.0f );
}

