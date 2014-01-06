module graphics.shaders.shaders;
import graphics.shaders.shader, graphics.shaders.glshader, graphics.shaders.dxshader;
import utility.filepath;

import std.string;

static class Shaders
{
static:
public:
	void initialize()
	{
		foreach( file; FilePath.scanDirectory( FilePath.Resources.Shaders ) )
		{
			Shader shader;
			string name = file.baseFileName.chomp( ".vs" ).chomp( ".fs" );

			if( file.fileName.indexOf( "*.fs.glsl" ) != -1 )
			{
				shader = new GLShader( file.directory ~ name ~ ".vs.glsl",
									   file.directory ~ name ~ ".fs.glsl" );
			}
			else if( file.fileName.indexOf( "*.fs.hlsl" ) != -1 )
			{
				shader = new DXShader( file.directory ~ name ~ ".vs.glsl",
									   file.directory ~ name ~ ".fs.glsl" );
			}

			shaders[ name ] = shader;
		}
	}

	void shutdown()
	{
		foreach( name, shader; shaders )
		{
			shader.shutdown();
			shaders.remove( name );
		}
	}

	Shader opIndex( string name )
	{
		return getShader( name );
	}

	Shader getShader( string name )
	{
		return shaders[ name ];
	}

private:
	Shader[ string ] shaders;
}
