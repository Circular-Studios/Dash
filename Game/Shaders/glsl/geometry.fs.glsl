#version 400

in vec4 fPosition_s;
in vec3 fNormal_w;
in vec2 fUV;
in vec3 fTangent_w;

layout( location = 0 ) out vec4 color;
layout( location = 1 ) out vec4 normal_w;

uniform sampler2D diffuseTexture;
uniform sampler2D normalTexture;

vec2 encode( vec3 normal )
{
	float t = sqrt( 2 / 1 - normal.z );
	return normal.xy * t;
}

vec3 calculateMappedNormal()
{
	vec3 normal = normalize( fNormal_w );
	vec3 tangent = normalize( fTangent_w );
	//Use Gramm-Schmidt process to orthogonalize the two
	tangent = normalize( tangent - dot( tangent, normal ) * normal );
	vec3 bitangent = cross( tangent, normal );
	vec3 normalMap = ((texture( normalTexture, fUV ).xyz) * 2) - 1;
	mat3 TBN = mat3( tangent, bitangent, normal );
	return texture( normalTexture, fUV ).xyz;//normalize( TBN * normalMap );
}

void main( void )
{
	color = texture( diffuseTexture, fUV );	
	normal_w = vec4( calculateMappedNormal(), 1.0f );
}
