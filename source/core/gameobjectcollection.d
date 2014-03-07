/**
 * Defines the GameObjectCollection class, which manages game objects and allows for batch operations on them.
 */
module core.gameobjectcollection;
import core, graphics, utility;

import yaml;

import std.path, std.parallelism;

/**
 * Manages a collection of GameObjects.
 */
shared final class GameObjectCollection
{
public:
	/// The AA of game objects managed.
	GameObject[string] objects;

	/// Allows functions to be called on this as if it were the AA.
	alias objects this;

	/**
	 * Load all objects inside the specified folder in FilePath.Objects.
	 * 
	 * Params:
	 * 	objectPath =			The folder location inside of /Objects to look for objects in.
	 */
	final void loadObjects( string objectPath = "" )
	{
		string[shared GameObject] parents;

		Config.processYamlDirectory(
			buildNormalizedPath( FilePath.Resources.Objects, objectPath ),
			( Node yml )
			{
				// Create the object
				auto object = GameObject.createFromYaml( yml );
				// Add to collection
				objects[ object.name ] = object;

				// If parent is specified, add it to the map
				string parentName;
				if( Config.tryGet( "Parent", parentName, yml ) )
				{
					parents[ object ] = parentName;
					//logInfo("Parent:", parentName, " for ", object.name );
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
	 * Params:
	 * 	func =				The function to call on each object.
	 * 	parallel =			Whether or not to execute function in parallel
	 * 
	 * Examples:
	 * ---
	 * goc.apply( go => go.update() );
	 * ---
	 */
	final void apply( void function( shared GameObject ) func, bool parallel = false )
	{
		if( parallel )
			foreach( value; parallel( objects.values ) )
				func( value );
		else
			foreach( value; objects.values )
				func( value );
	}

	/**
	 * Update all game objects.
	 */
	final void update( bool parallel = false )
	{
		apply( go => go.update(), parallel );
	}

	/**
	 * Draw all game objects.
	 */
	final void draw( bool parallel = false )
	{
		apply( go => go.draw(), parallel );
	}

	/**
	 * Get the object with the given key.
	 */
	final shared(GameObject) opIndex( string key )
	{
		return objects[ key ];
	}
}
