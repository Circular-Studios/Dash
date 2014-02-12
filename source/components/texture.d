/**
 * Defines the Texture class, which contains info for a texture loaded into the world.
 */
module components.texture;
import core.properties;
import components.component;
import graphics.graphics, graphics.shaders.shader;

import derelict.opengl3.gl3;
import derelict.freeimage.freeimage;

class Texture : Component
{
public:
	mixin Property!( "uint", "width" );
	mixin Property!( "uint", "height" );
	mixin Property!( "uint", "glID" );

	this( string filePath )
	{	
		super( null );
		
		filePath ~= "\0";
		auto imageData = FreeImage_ConvertTo32Bits( FreeImage_Load( FreeImage_GetFileType( filePath.ptr, 0 ), filePath.ptr, 0 ) );

		width = FreeImage_GetWidth( imageData );
		height = FreeImage_GetHeight( imageData );

		glGenTextures( 1, &_glID );
		glBindTexture( GL_TEXTURE_2D, glID );
		glTexImage2D(
			GL_TEXTURE_2D,
			0,
			GL_RGBA,
			width,
			height,
			0,
			GL_BGRA, //FreeImage loads in BGR format because fuck you
			GL_UNSIGNED_BYTE,
			cast(GLvoid*)FreeImage_GetBits( imageData ) );
		glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );

		FreeImage_Unload( imageData );
		glBindTexture( GL_TEXTURE_2D, 0 );
	}

	override void update()
	{

	}

	override void draw( Shader shader )
	{
		//shader.bindTexture( this );
	}

	override void shutdown()
	{
		glBindTexture( GL_TEXTURE_2D, 0 );
		glDeleteBuffers( 1, &_glID );
	}

}
