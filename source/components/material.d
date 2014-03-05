module components.material;
import core, components, graphics, utility;

import yaml;
import derelict.opengl3.gl3, derelict.freeimage.freeimage;
import std.variant, std.conv, std.string;

final class Material : IComponent
{
private:
	Texture _diffuse, _normal, _specular;

public:
	mixin( Property!(_diffuse, AccessModifier.Public) );
	mixin( Property!_normal );
	mixin( Property!_specular );

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

	override void update() { }
	override void shutdown() { }
}

class Texture
{
protected:
	uint _width, _height, _glID;

	this( ubyte* buffer )
	{
		glGenTextures( 1, &_glID );
		glBindTexture( GL_TEXTURE_2D, glID );
		updateBuffer( buffer );

		glBindTexture( GL_TEXTURE_2D, 0 );
	}

	void updateBuffer( ubyte* buffer )
	{
		glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA, _width, _height, 0, GL_BGRA ,GL_UNSIGNED_BYTE, cast(GLvoid*)buffer );
		glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
	}

public:
	mixin( Property!_width );
	mixin( Property!_height );
	mixin( Property!_glID );

	this( string filePath )
	{
		filePath ~= "\0";
		auto imageData = FreeImage_ConvertTo32Bits( FreeImage_Load( FreeImage_GetFileType( filePath.ptr, 0 ), filePath.ptr, 0 ) );

		width = FreeImage_GetWidth( imageData );
		height = FreeImage_GetHeight( imageData );

		this( cast(ubyte*)FreeImage_GetBits( imageData ) );

		FreeImage_Unload( imageData );
	}

	void shutdown()
	{
		glBindTexture( GL_TEXTURE_2D, 0 );
		glDeleteBuffers( 1, &_glID );
	}
}
