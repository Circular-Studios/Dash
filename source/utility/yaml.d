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
		// Initialize root node as map
		root = Node( [""], [""] );

		foreach( file; FilePath.scanDirectory( ".", "*.yaml" ) )
		{
			root[ stripExtension( file.relativePath ) ] = Loader( file.relativePath ).load();
		}
	}

	T get( T )( string path )
	{
		// Iterate until we find the end, and then return value
		Node current = root;

		try
		{
			foreach( word; split( path, "." ) )
				current = current[ word ];

			return current.as!T;
		}
		catch( YAMLException e )
		{
			Output.printMessage( OutputType.Error, "Path not found/invalid type: " ~ path );

			return 0;
		}
	}

private:
	Node root;
}
