/**
 * Defines the GameObjectCollection class, which manages game objects and allows for batch operations on them.
 */
module core.gameobjectcollection;
import core.gameobject;
import graphics.shaders;
import utility.filepath, utility.config;

import yaml;

import std.path;

final class GameObjectCollection
{
public:
	alias objects this;

	/**
	 * Load all objects inside the specified folder in FilePath.Objects.
	 */
	final void loadObjects( string objectPath = "" )
	{
		string[GameObject] parents;

		Config.processYamlDirectory(
			buildNormalizedPath( FilePath.Resources.Objects, objectPath ),
			( Node yml )
			{
				auto name = yml[ "Name" ].as!string;

				// Create the object
				auto object = GameObject.createFromYaml( yml );
				// Add to collection
				objects[ name ] = object;

				// If parent is specified, add it to the map
				string parentName;
				if( Config.tryGet( "Parent", parentName, yml ) )
				{
					parents[ object ] = parentName;
				}
			} );

		foreach( object, parentName; parents )
		{
			objects[ parentName ].addChild( object );
		}
	}

	/**
	 * Remove all objects from the collection.
	 */
	final void clearObjects()
	{
		foreach( key; objects.keys )
			objects.remove( key );
	}

	/**
	 * Call the given function on each game object.
	 * 
	 * Examples:
	 * ---
	 * goc.apply( go => go.update() );
	 * ---
	 */
	final void apply( void function( GameObject ) func )
	{
		foreach( value; objects.values )
			func( value );
	}

	/**
	 * Update all game objects.
	 */
	final void update()
	{
		apply( go => go.update() );
	}

	/**
	 * Draw all game objects.
	 */
	final void draw()
	{
		apply( go => go.draw() );
	}

private:
	GameObject[string] objects;
}
