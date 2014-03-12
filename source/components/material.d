module components.material;
import core, components, graphics, utility;

import yaml;
import derelict.opengl3.gl3, derelict.freeimage.freeimage;
import std.variant, std.conv, std.string;

shared final class Material : IComponent
{
private:
	Texture _diffuse, _normal, _specular;

public:
	mixin( Property!(_diffuse, AccessModifier.Public) );
	mixin( Property!(_normal, AccessModifier.Public) );
	mixin( Property!(_specular, AccessModifier.Public) );

	this()
	{
		_diffuse = _normal = _specular = defaultTex;
	}

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

shared class Texture
{
protected:
	uint _width, _height, _glID;

	this( ubyte* buffer )
	{
		glGenTextures( 1, cast(uint*)&_glID );
		glBindTexture( GL_TEXTURE_2D, glID );
		updateBuffer( buffer );

		glBindTexture( GL_TEXTURE_2D, 0 );
	}

	void updateBuffer( const ubyte* buffer )
	{
		// Set texture to update
		glBindTexture( GL_TEXTURE_2D, glID );

		// Update texture
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA, _width, _height, 0, GL_BGRA, GL_UNSIGNED_BYTE, cast(GLvoid*)buffer );
		glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );

		// Cleanup, unbind
		glBindTexture( GL_TEXTURE_2D, 0 );
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
		glDeleteBuffers( 1, cast(uint*)&_glID );
	}
}


@property Texture defaultTex()
{
	static Texture def;

	if( !def )
		def = new Texture( [0, 0, 0, 255] );

	return def;
}

static this()
{
	IComponent.initializers[ "Material" ] = ( Node yml, shared GameObject obj )
	{
		obj.material = Assets.get!Material( yml.get!string );
		return obj.material;
	};
}
