module graphics.shaders.glsl.directionallight;

package:


immutable string directionallightVS = q{
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
};

immutable string directionallightFS = q{
	#version 400

	struct DirectionalLight
	{
		vec3 color;
		vec3 direction;
	};

	in vec4 fPosition;
	in vec2 fUV;

	// this diffuse should be set to the geometry output
	uniform sampler2D diffuseTexture;
	uniform sampler2D normalTexture;
	uniform sampler2D depthTexture;
	uniform DirectionalLight light;
	uniform vec3 eyePosition_w;
	uniform mat4 invViewProj;

	// https://stackoverflow.com/questions/9222217/how-does-the-fragment-shader-know-what-variable-to-use-for-the-color-of-a-pixel
	out vec4 color;

	vec3 decode( vec2 enc )
	{
		float t = ( ( enc.x * enc.x ) + ( enc.y * enc.y ) ) / 4;
		float ti = sqrt( 1 - t );
		return vec3( ti * enc.x, ti * enc.y, -1 + t * 2 );
	}

	void main( void )
	{
		vec4 textureColor = texture( diffuseTexture, fUV );
		vec3 normal = texture( normalTexture, fUV ).xyz;

		// Diffuse lighting calculations
		float diffuseIntensity = clamp( dot( normal, -light.direction ), 0, 1 );

		// Specular lighting calculations
		// pixelPosition is essentially 3D screen space coordinates - x, y, z of the screen
		vec3 pixelPosition_s = vec3( fUV.x * 2.0f - 1.0f, fUV.y * 2.0f - 1.0f, texture( depthTexture, fUV ).x );
		// Multiplying screen space coordinates by the inverse viewProjection matrix gives you world coordinates
		vec3 pixelPosition_w = ( invViewProj * vec4( pixelPosition_s, 1.0f ) ).xyz;
		vec3 eyeDirection = normalize( ( pixelPosition_w - eyePosition_w).xyz );
		float specularIntensity = clamp( dot( eyeDirection, reflect( -light.direction, normal ) ), 0, 1 );

		vec3 diffuse = ( diffuseIntensity * light.color ) * textureColor.xyz;
		// texturecolor.w stores specular exponent
		vec3 specular = ( pow( specularIntensity, textureColor.w ) * light.color );
		color = vec4( ( diffuse + specular ), 1.0f );
	}
};