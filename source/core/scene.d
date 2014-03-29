/**
 * This module defines the Scene class, 
 * 
 */
module core.scene;
import core, graphics, utility;

import std.path;

shared final class Scene
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
     *  objectPath =            The folder location inside of /Objects to look for objects in.
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
    final void clear()
    {
        foreach( key; objects.keys )
            objects.remove( key );
    }
}
