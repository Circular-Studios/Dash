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
		foreach( file; FilePath.scanDirectory( FilePath.Resources.Shaders, "*.fs.glsl" ) )
		{
			// Strip .fs from file name
			string name = file.baseFileName[ 0..$-4 ];
			shaders[ name ] = new GLShader( file.directory ~ name ~ ".vs.glsl", file.fullPath );
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
		auto shader = name in shaders;
		return shader is null ? null : *shader;
	}

private:
	Shader[string] shaders;
}
