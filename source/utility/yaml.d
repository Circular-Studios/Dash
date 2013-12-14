module utility.yaml;
import utility.filepath, utility.output;

import std.stdio;

import std.path, std.array;
import yaml;

static class Yaml
{
static:
public:
	void initialize()
	{
		root = Node( [""], [""] );

		foreach( file; FilePath.scanDirectory( ".", "*.yaml" ) )
		{
			root[ stripExtension( file.relativePath ) ] = Loader( file.relativePath ).load();
		}
	}

	T get( T )( string path )
	{
		Node current = root;

		try
		{
			foreach( word; split( path, "." ) )
			{
				current = current[ word ];
			}

			return current.as!T;
		}
		catch( YAMLException e )
		{
			Output.printMessage( OutputType.Error, "Path not found: " ~ path );

			return null;
		}
	}

private:
	Node root;
}
