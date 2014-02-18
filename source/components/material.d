module components.material;
import core.properties;
import components;
import graphics.graphics, graphics.shaders;
import utility.config;

import yaml;
import derelict.opengl3.gl3, derelict.freeimage.freeimage;
import std.variant, std.conv;

final class Material : Component
{
public:
	mixin Property!( "Texture", "diffuse" );
	mixin Property!( "Texture", "normal" );
	mixin Property!( "Texture", "specular" );

	/**
	* Create a Material from a Yaml node.
	*/
	static Material createFromYaml( Node yamlObj )
	{
		auto obj = new Material;
		Variant prop;

		if( Config.tryGet!string( "Diffuse", prop, yamlObj ) )
			obj.diffuse = Assets.get!Texture( prop.get!string );

		if( Config.tryGet!string( "Normal", prop, yamlObj ) )
			obj.normal = Assets.get!Texture( prop.get!string );

		if( Config.tryGet!string( "Specular", prop, yamlObj ) )
			obj.specular = Assets.get!Texture( prop.get!string );

		return obj;
	}

	this()
	{
		super( null );
	}

	override void update() { }
	override void draw( Shader shader ) { }
	override void shutdown() { }

	final void bind( Shader shader )
	{
		GLint textureLocation = glGetUniformLocation( shader.programID, "diffuseTexture\0" );
		glUniform1i( textureLocation, 0 );
		glActiveTexture( GL_TEXTURE0 );
		glBindTexture( GL_TEXTURE_2D, diffuse.glID );

		textureLocation = glGetUniformLocation( shader.programID, "normalTexture\0" );
		glUniform1i( textureLocation, 1 );
		glActiveTexture( GL_TEXTURE1 );
		glBindTexture( GL_TEXTURE_2D, normal.glID );
	}
}

final class Texture
{
public:
	mixin Property!( "uint", "width" );
	mixin Property!( "uint", "height" );
	mixin Property!( "uint", "glID" );

	this( string filePath )
	{
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
		glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );

		FreeImage_Unload( imageData );
		glBindTexture( GL_TEXTURE_2D, 0 );
	}

	void shutdown()
	{
		glBindTexture( GL_TEXTURE_2D, 0 );
		glDeleteBuffers( 1, &_glID );
	}
}
