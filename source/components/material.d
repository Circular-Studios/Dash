module components.material;
import core, components, graphics, utility;

import yaml;
import derelict.opengl3.gl3, derelict.freeimage.freeimage;
import std.variant, std.conv;

shared final class Material : IComponent
{
private:
	Texture _diffuse, _normal, _specular;

public:
	mixin( Property!_diffuse );
	mixin( Property!_normal );
	mixin( Property!_specular );

	/**
	* Create a Material from a Yaml node.
	*/
	static shared(Material) createFromYaml( Node yamlObj )
	{
		auto obj = new shared Material;
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

shared final class Texture
{
private:
	uint _width, _height, _glID;

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

		glGenTextures( 1, cast(uint*)&_glID );
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
		glDeleteBuffers( 1, cast(uint*)&_glID );
	}
}

static this()
{
	IComponent.initializers[ "Material" ] = ( Node yml, shared GameObject obj )
	{
		obj.material = Assets.get!Material( yml.get!string );
		return obj.material;
	};
}
