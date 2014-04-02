/**
 * This module defines the Scene class, 
 * 
 */
module core.scene;
import core, components, graphics, utility;

import std.path;

shared final class Scene
{
public:
    /// The AA of game objects managed.
    GameObject[string] objects;

    /// Allows functions to be called on this as if it were the AA.
    alias objects this;

    /// The camera to render with.
    Camera camera;

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
            
            // If the object doesn't define a name, error.
            if( object.name != AnonymousName )
            {
                if( object.name in objects )
                    logWarning( "Duplicate object of name ", object.name, " detected." );

                // Add to collection
                objects[ object.name ] = object;
            }
            else
            {
                logError( "Anonymous objects at the top level are not supported." );
                assert( false );
            }
            
            // This goes through each child defined inline and adds it to the scene.
            // An inline child may look like:
            // Name: objParent
            // Children:
            //     - Name: objChild
            //     - Mesh: myMesh
            // In this case, objChild would be added to the scene.
            foreach( child; object.children )
            {
                objects[ child.name ] = child;
                logInfo( "Adding child ", child.name, " of ", object.name, " to collection." );
            }
        }
        
        // Make sure the child graph is complete.
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
