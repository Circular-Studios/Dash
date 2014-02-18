/**
 * Defines the static class Config, which handles all configuration options.
 */
module utility.config;
import utility.filepath;

// Imports for conversions
import core.dgame : GameState;
import components.assets;
import graphics.shaders;
import utility.output : Verbosity;
import math.vector, math.quaternion;

import yaml;

import std.array, std.conv, std.string, std.path, std.typecons, std.variant;

/**
 * Static class which handles the configuration options and YAML interactions.
 */
final abstract class Config
{
public static:
	final void initialize()
	{
		constructor = new Constructor;

		constructor.addConstructorScalar( "!Vector2", &constructVector2 );
		constructor.addConstructorMapping( "!Vector2-Map", &constructVector2 );
		constructor.addConstructorScalar( "!Vector3", &constructVector3 );
		constructor.addConstructorMapping( "!Vector3-Map", &constructVector2 );
		constructor.addConstructorScalar( "!Quaternion", &constructQuaternion );
		constructor.addConstructorMapping( "!Quaternion-Map", &constructQuaternion );
		constructor.addConstructorScalar( "!GameState", &constructConv!GameState );
		constructor.addConstructorScalar( "!Verbosity", &constructConv!Verbosity );
		constructor.addConstructorScalar( "!Shader", ( ref Node node ) => Shaders.get( node.get!string ) );
		//constructor.addConstructorScalar( "!Texture", ( ref Node node ) => Assets.get!Texture( node.get!string ) );
		//constructor.addConstructorScalar( "!Mesh", ( ref Node node ) => Assets.get!Mesh( node.get!string ) );
		//constructor.addConstructorScalar( "!Material", ( ref Node node ) => Assets.get!Material( node.get!string ) );

		config = loadYaml( FilePath.Resources.Config );
	}

	/**
	 * Load a yaml file with the engine-specific mappings.
	 */
	final Node loadYaml( string path )
	{
		auto loader = Loader( path );
		loader.constructor = constructor;
		return loader.load();
	}

	/**
	 * Process all yaml files in a directory, and call the callback with all the root level nodes.
	 */
	final void processYamlDirectory( string folder, void delegate( Node ) callback )
	{
		foreach( file; FilePath.scanDirectory( folder, "*.yml" ) )
		{
			auto object = Config.loadYaml( file.fullPath );

			if( object.isSequence() )
				foreach( Node innerObj; object )
					callback( innerObj );
			else
				callback( object );
		}
	}

	/**
	 * Get the element, cast to the given type, at the given path, in the given node.
	 */
	final T get( T )( string path, Node node = config )
	{
		Node current = node;
		string left;
		string right = path;

		while( true )
		{
			auto split = right.indexOf( '.' );
			if( split == -1 )
			{
				return current[ right ].get!T;
			}
			else
			{
				left = right[ 0..split ];
				right = right[ split + 1..$ ];
				current = current[ left ];
			}
		}
	}

	/**
	* Try to get the value at path, assign to result, and return success.
	*/
	final bool tryGet( T )( string path, ref T result, Node node = config )
	{
		Node res;
		bool found = tryGet( path, res, node );
		if( found )
			result = res.get!T;
		return found;
	}

	/// ditto
	final bool tryGet( T: Node )( string path, ref T result, Node node = config )
	{
		Node current;
		string left;
		string right = path;

		for( current = node; right.length; )
		{
			auto split = right.indexOf( '.' );

			if( split == -1 )
			{
				left = right;
				right.length = 0;
			}
			else
			{
				left = right[ 0..split ];
				right = right[ split + 1..$ ];
			}

			if( !current.containsKey( left ) )
				return false;

			current = current[ left ];
		}

		result = current;
		return true;
	}

	/// ditto
	final bool tryGet( T = Node )( string path, ref Variant result, Node node = config )
	{
		// Get the value
		T temp;
		bool found = tryGet!T( path, temp, node );

		// Assign and return results
		if( found )
			result = temp;

		return found;
	}

	@disable bool tryGet( T: Variant )( string path, ref T result, Node node = config );

	/**
	 * Get element as a file path.
	 */
	final string getPath( string path )
	{
		return FilePath.ResourceHome ~ get!string( path );//buildNormalizedPath( FilePath.ResourceHome, get!string( path ) );;
	}

private:
	Node config;
	Constructor constructor;
}

Vector!2 constructVector2( ref Node node )
{
	auto result = new Vector!2;

	if( node.isMapping )
	{
		result.values[ 0 ] = node[ "x" ].as!float;
		result.values[ 1 ] = node[ "y" ].as!float;
	}
	else if( node.isScalar )
	{
		string[] vals = node.as!string.split();

		if( vals.length != 2 )
		{
			throw new Exception( "Invalid number of values: " ~ node.as!string );
		}

		result.x = vals[ 0 ].to!float;
		result.y = vals[ 1 ].to!float;
	}

	return result;
}

Vector!3 constructVector3( ref Node node )
{
	auto result = new Vector!3;

	if( node.isMapping )
	{
		result.values[ 0 ] = node[ "x" ].as!float;
		result.values[ 1 ] = node[ "y" ].as!float;
		result.values[ 2 ] = node[ "z" ].as!float;
	}
	else if( node.isScalar )
	{
		string[] vals = node.as!string.split();

		if( vals.length != 3 )
		{
			throw new Exception( "Invalid number of values: " ~ node.as!string );
		}

		result.x = vals[ 0 ].to!float;
		result.y = vals[ 1 ].to!float;
		result.z = vals[ 2 ].to!float;
	}

	return result;
}

Quaternion constructQuaternion( ref Node node )
{
	Quaternion result = new Quaternion;

	if( node.isMapping )
	{
		result.x = node[ "x" ].as!float;
		result.y = node[ "y" ].as!float;
		result.z = node[ "z" ].as!float;
		result.w = node[ "w" ].as!float;
	}
	else if( node.isScalar )
	{
		string[] vals = node.as!string.split();

		if( vals.length != 3 )
		{
			throw new Exception( "Invalid number of values: " ~ node.as!string );
		}

		result.x = vals[ 0 ].to!float;
		result.y = vals[ 1 ].to!float;
		result.z = vals[ 2 ].to!float;
		result.w = vals[ 3 ].to!float;
	}

	return result;
}

T constructConv( T )( ref Node node ) if( is( T == enum ) )
{
	if( node.isScalar )
	{
		return node.as!string.to!T;
	}
	else
	{
		throw new Exception( "Enum must be represented as a scalar." );
	}
}

unittest
{
	import std.stdio;
	writeln( "Dash Config get unittest" );

	auto n1 = Node( [ "test1": 10 ] );

	assert( Config.get!int( "test1", n1 ) == 10, "Config.get error." );

	try
	{
		Config.get!int( "dontexist", n1 );
		assert( false, "Config.get didn't throw." );
	}
	catch { }
}
unittest
{
	import std.stdio;
	writeln( "Dash Config tryGet unittest" );

	auto n1 = Node( [ "test1": 10 ] );

	int val;
	assert( Config.tryGet( "test1", val, n1 ), "Config.tryGet failed." );
	assert( !Config.tryGet( "dontexist", val, n1 ), "Config.tryGet returned true." );
}

