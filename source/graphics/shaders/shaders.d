module graphics.shaders.shaders;
import graphics.graphics, graphics.shaders.shader, graphics.shaders.glshader, graphics.shaders.dxshader;
import utility.filepath;

import std.string;

static class Shaders
{
static:
public:
	void initialize()
	{
		string path, blob;
		if( Graphics.activeAdapter == GraphicsAdapter.OpenGL )
		{
			path = FilePath.Resources.GLSLShaders;
			blob = "*.fs.glsl";
		}
		else if( Graphics.activeAdapter == GraphicsAdapter.DirectX )
		{
			path = FilePath.Resources.HLSLShaders;
			blob = "*.fs.hlsl";
		}

		foreach( file; FilePath.scanDirectory( path, blob ) )
		{
			string name = file.baseFileName.chomp( ".fs" );

			if( file.fileName.indexOf( ".fs.glsl" ) != -1 )
			{
				shaders[ name ] = new GLShader( file.directory ~ name ~ ".vs.glsl", file.fullPath );
			}
			else if( file.fileName.indexOf( ".fs.hlsl" ) != -1 )
			{
				shaders[ name ] = new DXShader( file.directory ~ name ~ ".vs.hlsl", file.fullPath );
			}
		}

		shaders.rehash();
	}

	void shutdown()
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

	Shader opIndex( string name )
	{
		return get( name );
	}

	Shader get( string name )
	{
		return shaders[ name ];
	}

private:
	Shader[string] shaders;
}
