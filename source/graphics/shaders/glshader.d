module graphics.shaders.glshader;
import core.properties;
import components.mesh, components.texture, components.lights.light, components.lights.directional;
import graphics.shaders.shader;
import utility.filepath, utility.output;
import math.matrix, math.vector;
import derelict.opengl3.gl3;

import std.traits;

public enum ShaderUniform 
{
	World = "world",
	WorldView = "worldView",
	WorldViewProjection = "worldViewProj",
	DiffuseTexture = "diffuseTexture",
	NormalTexture = "normalTexture",
	DepthTexture = "depthTexture",
	DirectionalLightDirection = "dirLight.direction",
	DirectionalLightColor = "dirLight.color",
	AmbientLight = "ambientLight"
}

final package class GLShader : Shader
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

	final void setUniform( ShaderUniform uniform, const float value )
	{
		auto currentUniform = getUniformLocation( uniform );
		
		glUniform1f( currentUniform, value );
	}

	final void setUniformMatrix( ShaderUniform uniform, const Matrix!4 matrix )
	{
		auto currentUniform = getUniformLocation( uniform );

		glUniformMatrix4fv( currentUniform, 1, false, matrix.matrix.ptr.ptr );
	}

	void bindLight( Light light )
	{
		if( typeid(light) == typeid(DirectionalLight) )
		{
			// buffer light here
			glUniform3f( getUniformLocation( ShaderUniform.DirectionalLightDirection ), (cast(DirectionalLight)light).direction.x, (cast(DirectionalLight)light).direction.y, (cast(DirectionalLight)light).direction.z );
			glUniform3f( getUniformLocation( ShaderUniform.DirectionalLightColor ), light.color.x, light.color.y, light.color.z );
		}
		else //Base light class means ambient light
		{
			glUniform3f( getUniformLocation( ShaderUniform.AmbientLight ), light.color.x, light.color.y, light.color.z );
		}

	}

	override void shutdown()
	{

	}
}
