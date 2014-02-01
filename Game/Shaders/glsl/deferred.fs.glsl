#version 400

in vec3 fPosition;
in vec3 fNormal;
in vec2 fUV;
in vec3 fTangent;
in vec3 fBinormal;

layout( location = 0 ) out vec4 color;
layout( location = 1 ) out vec4 normal;

uniform sampler2D diffuseTexture;
uniform sampler2D normalTexture;

void main( void )
{
	vec4 textureColor = texture( diffuseTexture, fUV );
	color = textureColor;
	vec4 normalMap = texture( normalTexture, fUV );
	normalMap = -( (normalMap * 2.0f) - 1.0f );
	normal = vec4( normalize( fNormal + ( normalMap.x * fTangent ) + ( normalMap.y * fBinormal ) ), 1.0f );
}