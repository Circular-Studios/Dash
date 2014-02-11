module components.material;
import core.properties;
import components;
import graphics.shaders.shader, graphics.shaders.glshader;
import utility.config;

import yaml;
import derelict.opengl3.gl3;
import std.variant, std.conv;

class Material : Component
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

	void bind( Shader shader )
	{
		GLint textureLocation = glGetUniformLocation( (cast(GLShader)shader).programID, "diffuseTexture\0" );
		glUniform1i( textureLocation, 0 );
		glActiveTexture( GL_TEXTURE0 );
		glBindTexture( GL_TEXTURE_2D, diffuse.glID );

		textureLocation = glGetUniformLocation( (cast(GLShader)shader).programID, "normalTexture\0" );
		glUniform1i( textureLocation, 1 );
		glActiveTexture( GL_TEXTURE1 );
		glBindTexture( GL_TEXTURE_2D, normal.glID );
	}
}
