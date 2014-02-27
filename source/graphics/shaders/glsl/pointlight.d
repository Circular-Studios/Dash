module graphics.shaders.glsl.pointlight;

package:

immutable string pointlightVS = q{
#version 400
	
	layout(location = 0) in vec3 vPosition_m;
	layout(location = 1) in vec2 vUV;
	layout(location = 2) in vec3 vNormal_m;
	layout(location = 3) in vec3 vTangent_m;
	
	out vec4 fPosition_s;
	//out vec3 fNormal_w;
	//out vec2 fUV;
	//out vec3 fTangent_w;
	//out vec3 fBitangent_w;
	
	uniform mat4 world;
	uniform mat4 worldView;
	uniform mat4 worldViewProj;
	
	void main( void )
	{
		// gl_Position is like SV_Position
		fPosition_s = worldViewProj * vec4( vPosition_m, 1.0f );
		gl_Position = fPosition_s;
		//fUV = vUV;
		
		//fNormal_w = ( world * vec4( vNormal_m, 0.0f ) ).xyz;
		//fTangent_w =  ( world * vec4( vTangent_m, 0.0f ) ).xyz;
	}
};

immutable string pointlightFS = q{
#version 400

	struct PointLight{
		vec3 pos;
		vec3 color;
		float radius;
	};
	
	in vec4 fPosition_s;
	//in vec3 fNormal_w;
	//in vec2 fUV;
	//in vec3 fTangent_w;
	
	layout( location = 0 ) out vec4 color;
	
	uniform sampler2D diffuseTexture;
	uniform sampler2D normalTexture;
	uniform sampler2D depthTexture;
	uniform PointLight light;

	void main( void )
	{
		vec4 textureColor = texture( diffuseTexture, fPosition_s.xy ).xyz;
		vec3 normal = texture( normalTexture, fPosition_s.xy ).xyz;

	}
};

