module graphics.shaders;
import core.properties;
import components;
import graphics.graphics;
import math.matrix, math.vector;
import utility.filepath, utility.output;

import derelict.opengl3.gl3;
import std.string, std.traits;

final abstract class Shaders
{
public static:
	final void initialize()
	{
		shaders[ "geometry" ] = new Shader( "geometry", geometryVS, geometryFS, true );
		shaders[ "lighting" ] = new Shader( "lighting", lightingVS, lightingFS, true );
		foreach( file; FilePath.scanDirectory( FilePath.Resources.Shaders, "*.fs.glsl" ) )
		{
			// Strip .fs from file name
			string name = file.baseFileName[ 0..$-3 ];
			if(name != "geometry" && name != "lighting")
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
		auto shader = name in shaders;
		return shader is null ? null : *shader;
	}

private:
	Shader[string] shaders;
}

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

	void shutdown()
	{

	}
}

immutable string geometryVS = q{
#version 400

layout(location = 0) in vec3 vPosition_m;
layout(location = 1) in vec2 vUV;
layout(location = 2) in vec3 vNormal_m;
layout(location = 3) in vec3 vTangent_m;

out vec4 fPosition_s;
out vec3 fNormal_w;
out vec2 fUV;
out vec3 fTangent_w;
out vec3 fBitangent_w;

uniform mat4 world;
uniform mat4 worldView;
uniform mat4 worldViewProj;

void main( void )
{
	// gl_Position is like SV_Position
	fPosition_s = worldViewProj * vec4( vPosition_m, 1.0f );
	gl_Position = fPosition_s;
	fUV = vUV;

	fNormal_w = ( world * vec4( vNormal_m, 0.0f ) ).xyz;
	fTangent_w =  ( world * vec4( vTangent_m, 0.0f ) ).xyz;
}
};

immutable string geometryFS = q{
#version 400

in vec4 fPosition_s;
in vec3 fNormal_w;
in vec2 fUV;
in vec3 fTangent_w;

layout( location = 0 ) out vec4 color;
layout( location = 1 ) out vec4 normal_w;

uniform sampler2D diffuseTexture;
uniform sampler2D normalTexture;

vec2 encode( vec3 normal )
{
	float t = sqrt( 2 / 1 - normal.z );
	return normal.xy * t;
}

vec3 calculateMappedNormal()
{
	vec3 normal = normalize( fNormal_w );
	vec3 tangent = normalize( fTangent_w );
	//Use Gramm-Schmidt process to orthogonalize the two
	tangent = normalize( tangent - dot( tangent, normal ) * normal );
	vec3 bitangent = cross( tangent, normal );
	vec3 normalMap = ((texture( normalTexture, fUV ).xyz) * 2) - 1;
	mat3 TBN = mat3( tangent, bitangent, normal );
	return normalize( TBN * normalMap );
}

void main( void )
{
	color = texture( diffuseTexture, fUV );	
	normal_w = vec4( calculateMappedNormal(), 1.0f );
}
};

immutable string lightingVS = q{
#version 400

layout(location = 0) in vec3 vPosition_s;
layout(location = 1) in vec2 vUV;

out vec4 fPosition_s;
out vec2 fUV;

void main( void )
{
	fPosition_s = vec4( vPosition_s, 1.0f );
	gl_Position = fPosition_s;
	fUV = vUV;
}
};

immutable string lightingFS = q{
#version 400

struct DirectionalLight
{
	vec3 color;
	vec3 direction;
};

in vec4 fPosition;
in vec2 fUV;

uniform sampler2D diffuseTexture;
uniform sampler2D normalTexture;
uniform sampler2D depthTexture;
uniform DirectionalLight dirLight;
uniform vec3 ambientLight;

// https://stackoverflow.com/questions/9222217/how-does-the-fragment-shader-know-what-variable-to-use-for-the-color-of-a-pixel
out vec4 color;

vec3 decode( vec2 enc )
{
	float t = ( ( enc.x * enc.x ) + ( enc.y * enc.y ) ) / 4;
	float ti = sqrt( 1 - t );
	return vec3( ti * enc.x, ti * enc.y, -1 + t * 2 );
}

void main( void )
{
	vec4 textureColor = texture( diffuseTexture, fUV );
	vec3 normal = texture( normalTexture, fUV ).xyz;

	// temp vars until we get lights in
	//vec3 lightDirection = vec3( 0.0f, -1.0f, 0.5f );
	//vec4 diffuseColor = vec4( 1.0f, 1.0f, 1.0f, 1.0f );

	float diffuseIntensity = clamp( dot( normal, -dirLight.direction ), 0, 1 );
	color = ( vec4( ambientLight, 1.0f ) + ( diffuseIntensity * vec4( dirLight.color, 1.0f ) ) ) * textureColor;
}
};
