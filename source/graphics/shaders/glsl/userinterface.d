module graphics.shaders.glsl.userinterface;

package:

///
/// User interface shader
/// Just for transferring a texture (from awesomium) to the screen
///
immutable string userinterfaceVS = q{
	#version 400
	
	in vec3 vPosition;
	in vec2 vUV;

	out vec2 fUV;

	uniform mat4 Projection;

	void main( void )
	{
		gl_Position = Projection* vec4( vPosition, 1.0f );

		fUV = vUV;
	}
	
};

immutable string userinterfaceFS = q{
	#version 400

	in vec2 fUV;

	out vec4 color;

	uniform samler2D uiTexture;

	void main( void )
	{
		color = texture( uiTexture, fUV );
	}
	

};