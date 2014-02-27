module graphics.shaders.shaders;
import core.properties;
import components;
import graphics.graphics;
import graphics.shaders.glsl;
import utility.filepath, utility.output;

import derelict.opengl3.gl3;
import gl3n.linalg;

import std.string, std.traits;

/*
 * Other shader related constants
 */
public enum : string
{
	GeometryShader = "geometry",
	AmbientLightShader = "ambientlight",
	DirectionalLightShader = "direcionallight",
	PointLightShader = "pointlight"
}

/*
 * String constants for our shader uniforms
 */
public enum ShaderUniform 
{
	World = "world",
	WorldView = "worldView",
	WorldViewProjection = "worldViewProj",
	DiffuseTexture = "diffuseTexture",
	NormalTexture = "normalTexture",
	SpecularTexture = "specularTexture",
	DepthTexture = "depthTexture",
	LightDirection = "light.direction",
	LightColor = "light.color",
	LightRadius = "light.radius",
	LightPosition = "light.pos",
	AmbientLight = "ambientLight",
	EyePosition = "eyePosition_w",
	InverseViewProjection = "invViewProj",
}

final abstract class Shaders
{
public static:
	final void initialize()
	{
		shaders[ GeometryShader ] = new Shader( GeometryShader, geometryVS, geometryFS, true );
		shaders[ AmbientLightShader ] = new Shader( AmbientLightShader, ambientlightVS, ambientlightFS, true );
		shaders[ DirectionalLightShader ] = new Shader( DirectionalLightShader, directionallightVS, directionallightFS, true );
		shaders[ PointLightShader ] = new Shader( PointLightShader, pointlightVS, pointlightFS, true );
		foreach( file; FilePath.scanDirectory( FilePath.Resources.Shaders, "*.fs.glsl" ) )
		{
			// Strip .fs from file name
			string name = file.baseFileName[ 0..$-3 ];
			if( name !in [ EnumMembers!ShaderUniform ] )
			{
				shaders[ name ] = new Shader( name, file.directory ~ "\\" ~ name ~ ".vs.glsl", file.fullPath );
			}
			else
			{
				log( OutputType.Warning, "Shader not loaded: Shader found which would overwrite " ~ name ~ " shader" );
			}
		}

		shaders.rehash();
	}

	final void shutdown()
	{
		foreach_reverse( index; 0 .. shaders.length )
		{
			auto name = shaders.keys[ index ];
			shaders[ name ].shutdown();
			shaders.remove( name );
		}
		/*foreach( name, shader; shaders )
		{
			shader.shutdown();
			shaders.remove( name );
		}*/
	}

	final Shader opIndex( string name )
	{
		return get( name );
	}

	final Shader get( string name )
	{
		Shader* shader = name in shaders;
		return shader is null ? null : *shader;
	}

private:
	Shader[string] shaders;
}

final package class Shader
{
public:
	mixin Property!( "uint", "programID", "protected" );
	mixin Property!( "uint", "vertexShaderID", "protected" );
	mixin Property!( "uint", "fragmentShaderID", "protected" );
	mixin Property!( "string", "shaderName", "protected" );
	protected int[string] uniformLocations;

	this(string name, string vertex, string fragment, bool preloaded = false )
	{
		shaderName = name;
		// Create shader
        vertexShaderID = glCreateShader( GL_VERTEX_SHADER );
        fragmentShaderID = glCreateShader( GL_FRAGMENT_SHADER );
        programID = glCreateProgram();

		if(!preloaded)
		{
			auto vertexFile = new FilePath( vertex );
			auto fragmentFile = new FilePath( fragment );
			string vertexBody = vertexFile.getContents();
			string fragmentBody = fragmentFile.getContents();
			compile( vertexBody, fragmentBody );
		}
		else
		{
			compile( vertex, fragment );
		}
	}

	void compile( string vertexBody, string fragmentBody )
	{
		auto vertexCBody = vertexBody.ptr;
		auto fragmentCBody = fragmentBody.ptr;
		int vertexSize = cast(int)vertexBody.length;
		int fragmentSize = cast(int)fragmentBody.length;

		glShaderSource( vertexShaderID, 1, &vertexCBody, &vertexSize );
		glShaderSource( fragmentShaderID, 1, &fragmentCBody, &fragmentSize );

		GLint compileStatus = GL_TRUE;
		glCompileShader( vertexShaderID );
		glGetShaderiv( vertexShaderID, GL_COMPILE_STATUS, &compileStatus );
		if( compileStatus != GL_TRUE )
		{
			log( OutputType.Error, shaderName ~ " Vertex Shader compile error" );
			char[1000] errorLog;
			auto info = errorLog.ptr;
			glGetShaderInfoLog( vertexShaderID, 1000, null, info );
			log( OutputType.Error, errorLog );
			assert(false);
		}

		glCompileShader( fragmentShaderID );
		glGetShaderiv( fragmentShaderID, GL_COMPILE_STATUS, &compileStatus );
		if( compileStatus != GL_TRUE )
		{
			log( OutputType.Error, shaderName ~ " Fragment Shader compile error" );
			char[1000] errorLog;
			auto info = errorLog.ptr;
			glGetShaderInfoLog( fragmentShaderID, 1000, null, info );
			log( OutputType.Error, errorLog );
			assert(false);
		}

		// Attach shaders to program
        glAttachShader( programID, vertexShaderID );
        glAttachShader( programID, fragmentShaderID );
		glLinkProgram( programID );

		bindUniforms();

		glGetProgramiv( programID, GL_LINK_STATUS, &compileStatus );
        if( compileStatus != GL_TRUE )
        {
			log( OutputType.Error, shaderName ~ " Shader program linking error" );
			char[1000] errorLog;
			auto info = errorLog.ptr;
			glGetProgramInfoLog( programID, 1000, null, info );
			log( OutputType.Error, errorLog );
			assert(false);
		}
	}

	void bindUniforms()
	{
		//uniform is the *name* of the enum member not it's value
		foreach( uniform; [ EnumMembers!ShaderUniform ] )
		{
			//thus we use the mixin to get the value at compile time
			int uniformLocation = glGetUniformLocation( programID, uniform.ptr );

			uniformLocations[ uniform ] = uniformLocation;
		}
	}

	int getUniformLocation( ShaderUniform uniform )
	{
		return uniformLocations[ uniform ];
	}

	final void bindUniform1f( ShaderUniform uniform, const float value )
	{
		glUniform1f( getUniformLocation( uniform ), value );
	}

	final void bindUniformMatrix4fv( ShaderUniform uniform, mat4 matrix )
	{
		glUniformMatrix4fv( getUniformLocation( uniform ), 1, true, matrix.value_ptr );
	}


	/*
	 * Binds diffuse, normal, and specular textures to the shader
	 */
	final void bindMaterial( Material material )
	{
		//This is finding the uniform for the given texture, and setting that texture to the appropriate one for the object
		glUniform1i( getUniformLocation( ShaderUniform.DiffuseTexture ), 0 );
		glActiveTexture( GL_TEXTURE0 );
		glBindTexture( GL_TEXTURE_2D, material.diffuse.glID );

		glUniform1i( getUniformLocation( ShaderUniform.NormalTexture ), 1 );
		glActiveTexture( GL_TEXTURE1 );
		glBindTexture( GL_TEXTURE_2D, material.normal.glID );

		glUniform1i( getUniformLocation( ShaderUniform.SpecularTexture ), 2 );
		glActiveTexture( GL_TEXTURE2 );
		glBindTexture( GL_TEXTURE_2D, material.specular.glID );
	}

	/*
	 * Set the ambient light
	 */
	final void bindAmbientLight( AmbientLight light )
	{
		glUniform3f( getUniformLocation( ShaderUniform.AmbientLight ), light.color.x, light.color.y, light.color.z );
	}

	/*
	 * Set the (currently only 1 possible) directional light
	 */
	final void bindDirectionalLight( DirectionalLight light )
	{
		glUniform3f( getUniformLocation( ShaderUniform.DirectionalLightDirection ), light.direction.x, light.direction.y, light.direction.z );
		glUniform3f( getUniformLocation( ShaderUniform.DirectionalLightColor ), light.color.x, light.color.y, light.color.z );
	}

	/*
	 * Sets the eye position for lighting calculations
	 */
	final void setEyePosition( vec3 pos )
	{
		glUniform3f( getUniformLocation( ShaderUniform.EyePosition ), pos.x, pos.y, pos.z );
	}

	void shutdown()
	{
		// please write me :(
	}
}


