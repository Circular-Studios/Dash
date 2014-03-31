module graphics.shaders.shaders;
import core, components, graphics, utility;
import graphics.shaders.glsl;

import derelict.opengl3.gl3;
import gl3n.linalg;

import std.string, std.traits;

/*
 * String constants for shader names
 */
public enum : string
{
	GeometryShader = "geometry",
	AnimatedGeometryShader = "animatedgeometry",
	AmbientLightShader = "ambientlight",
	DirectionalLightShader = "direcionallight",
	PointLightShader = "pointlight",
	UserInterfaceShader = "userinterface",
}

/*
 * String constants for our shader uniforms
 */
public enum ShaderUniform 
{
	/// Matrices
	World = "world",
	WorldProj = "worldProj", // used this for scaling & orthogonal UI drawing
	WorldView = "worldView",
	WorldViewProjection = "worldViewProj",
	InverseViewProjection = "invViewProj",
	/// Textures
	UITexture = "uiTexture",
	DiffuseTexture = "diffuseTexture",
	NormalTexture = "normalTexture",
	SpecularTexture = "specularTexture",
	DepthTexture = "depthTexture",
	/// Lights
	LightDirection = "light.direction",
	LightColor = "light.color",
	LightRadius = "light.radius",
	LightPosition = "light.pos_w",
	EyePosition = "eyePosition_w",
	/// Animations
	Bones = "bones",
}

final abstract class Shaders
{
public static:
	final void initialize()
	{
		shaders[ GeometryShader ] = new Shader( GeometryShader, geometryVS, geometryFS, true );
		shaders[ AnimatedGeometryShader ] = new Shader( AnimatedGeometryShader, animatedGeometryVS, geometryFS, true ); // Only VS changed, FS stays the same
		shaders[ AmbientLightShader ] = new Shader( AmbientLightShader, ambientlightVS, ambientlightFS, true );
		shaders[ DirectionalLightShader ] = new Shader( DirectionalLightShader, directionallightVS, directionallightFS, true );
		shaders[ PointLightShader ] = new Shader( PointLightShader, pointlightVS, pointlightFS, true );
		shaders[ UserInterfaceShader ] = new Shader( UserInterfaceShader, userinterfaceVS, userinterfaceFS, true );
		foreach( file; FilePath.scanDirectory( FilePath.Resources.Shaders, "*.fs.glsl" ) )
		{
			// Strip .fs from file name
			string name = file.baseFileName[ 0..$-3 ];
			// if statement hitler
			// blame: Tyler
			if( name != GeometryShader &&
			   name != AnimatedGeometryShader &&
			   name != AmbientLightShader &&
			   name != DirectionalLightShader &&
			   name != PointLightShader )
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
private:
	uint _programID, _vertexShaderID, _fragmentShaderID;
	string _shaderName;

public:
	mixin( Property!_programID );
	mixin( Property!_vertexShaderID );
	mixin( Property!_fragmentShaderID );
	mixin( Property!_shaderName );
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

	/*
	 * Pass through for glUniform1f
	 */
	final void bindUniform1f( ShaderUniform uniform, const float value )
	{
		glUniform1f( getUniformLocation( uniform ), value );
	}

	/*
	 * Pass through for glUniform 3f
	 * Passes to the shader in XYZ order
	 */
	final void bindUniform3f( ShaderUniform uniform, const shared vec3 value )
	{
		glUniform3f( getUniformLocation( uniform ), value.x, value.y, value.z );
	}

	/*
	 *  pass through for glUniformMatrix4fv
	 */
	final void bindUniformMatrix4fv( ShaderUniform uniform, shared mat4 matrix )
	{
		glUniformMatrix4fv( getUniformLocation( uniform ), 1, true, matrix.value_ptr );
	}

	/*
	 * Bind an array of mat4s.
	 */
	final void bindUniformMatrix4fvArray( ShaderUniform uniform, shared mat4[] matrices )
	{
		float[] matptr;
		foreach( matrix; matrices )
		{
			for( int i = 0; i < 16; i++ )
			{
				matptr ~= matrix.value_ptr()[i];
			}
		}
		glUniformMatrix4fv( getUniformLocation( uniform ), cast(int)matrices.length, true, matptr.ptr );
	}

	/*
	 * Binds diffuse, normal, and specular textures to the shader
	 */
	final void bindMaterial( shared Material material )
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
	 * Binds a UI's texture
	 */
	 final void bindUI( shared UserInterface ui )
	 {
	 	glUniform1i( getUniformLocation( ShaderUniform.UITexture ), 0 );
	 	glActiveTexture( GL_TEXTURE0 );
	 	glBindTexture( GL_TEXTURE_2D, ui.view.glID );
	 }

	/*
	 * Bind an ambient light
	 */
	final void bindAmbientLight( shared AmbientLight light )
	{
		bindUniform3f( ShaderUniform.LightColor, light.color );
	}

	/*
	 * Bind a directional light
	 */
	final void bindDirectionalLight( shared DirectionalLight light )
	{
		bindUniform3f( ShaderUniform.LightDirection, light.direction );
		bindUniform3f( ShaderUniform.LightColor, light.color );
	}

	/*
	 * Bind a point light
	 */
	final void bindPointLight( shared PointLight light )
	{
		bindUniform3f( ShaderUniform.LightColor, light.color );
		bindUniform3f( ShaderUniform.LightPosition, light.owner.transform.worldPosition );
		bindUniform1f( ShaderUniform.LightRadius, light.radius );
	}


	/*
	 * Sets the eye position for lighting calculations
	 */
	final void setEyePosition( shared vec3 pos )
	{
		glUniform3f( getUniformLocation( ShaderUniform.EyePosition ), pos.x, pos.y, pos.z );
	}

	void shutdown()
	{
		// please write me :(
	}
}

