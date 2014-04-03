/**
 * Defines the GameObjectCollection class, which manages game objects and allows for batch operations on them.
 */
module core.gameobjectcollection;
import core, graphics, utility;

import yaml;

import std.path, std.parallelism;

deprecated( "Use Scenes instead." ):

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
		string[][shared GameObject] children;

		foreach( yml; loadYamlDocuments( buildNormalizedPath( FilePath.Resources.Objects, objectPath ) ) )
		{
			// Create the object
			auto object = GameObject.createFromYaml( yml, parents, children );
			
			if( object.name != AnonymousName )
			{
				// Add to collection
				objects[ object.name ] = object;
			}
			else
			{
				logError( "Anonymous objects at the top level are not supported." );
				assert( false );
			}
			
			foreach( child; object.children )
			{
				objects[ child.name ] = child;
				logInfo( "Adding child ", child.name, " of ", object.name, " to collection." );
			}
		}
		
		foreach( object, parentName; parents )
			objects[ parentName ].addChild( object );
		foreach( object, childNames; children )
			foreach( child; childNames )
				object.addChild( objects[ child ] );
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
	 * 	concurrent =			Whether or not to execute function in parallel
	 * 
	 * Examples:
	 * ---
	 * goc.apply( go => go.update() );
	 * ---
	 */
	final void apply( void function( shared GameObject ) func, bool concurrent = false )
	{
		if( concurrent )
			foreach( value; parallel( objects.values ) )
				func( value );
		else
			foreach( value; objects.values )
				func( value );
	}

	/**
	 * Update all game objects.
	 */
	final void update( bool concurrent = false )
	{
		apply( go => go.update(), concurrent );
	}

	/**
	 * Draw all game objects.
	 */
	final void draw( bool concurrent = false )
	{
		apply( go => go.draw(), concurrent );
	}
}
