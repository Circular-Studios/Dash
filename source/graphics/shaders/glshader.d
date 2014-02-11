module graphics.shaders.glshader;
import core.properties;
import components.mesh, components.texture;
import graphics.shaders.shader;
import utility.filepath, utility.output;
import math.matrix;
import derelict.opengl3.gl3;

import std.traits;

public enum ShaderUniform 
{
	World = "world",
	WorldView = "worldView",
	WorldViewProjection = "worldViewProj",
	DiffuseTexture = "diffuseTexture",
	NormalTexture = "normalTexture",
	DepthTexture = "depthTexture"
}

package class GLShader : Shader
{
public:
	mixin Property!( "uint", "programID", "protected" );
	mixin Property!( "uint", "vertexShaderID", "protected" );
	mixin Property!( "uint", "fragmentShaderID", "protected" );
	protected int[string] uniformLocations;

	this( string vertexPath, string fragmentPath )
	{
		// Create shader
        vertexShaderID = glCreateShader( GL_VERTEX_SHADER );
        fragmentShaderID = glCreateShader( GL_FRAGMENT_SHADER );
        programID = glCreateProgram();

		auto vertexFile = new FilePath( vertexPath );
		auto fragmentFile = new FilePath( fragmentPath );
		string vertexBody = vertexFile.getContents();
		string fragmentBody = fragmentFile.getContents();
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
			log( OutputType.Error, "Vertex Shader compile error" );
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
			log( OutputType.Error, "Fragment Shader compile error" );
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
			log( OutputType.Error, "Shader program linking error", vertexPath );
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

	void setUniform( ShaderUniform uniform, const float value )
	{
		auto currentUniform = getUniformLocation( uniform );
		
		glUniform1f( currentUniform, value );
	}

	void setUniformMatrix( ShaderUniform uniform, const Matrix!4 matrix )
	{
		auto currentUniform = getUniformLocation( uniform );

		glUniformMatrix4fv( currentUniform, 1, false, matrix.matrix.ptr.ptr );
	}

	override void shutdown()
	{

	}
}
