/**
 * This module defines the Scene class, TODO
 * 
 */
module core.scene;
import core, components, graphics, utility;

import std.path;

enum SceneName = "[scene]";

/**
 * TODO
 */
shared final class Scene
{
private:
    GameObject root;
    
package:
    GameObject[uint] objectById;
    uint[string] idByName;

public:
    /// The camera to render with.
    Camera camera;

    this()
    {
        root = new shared GameObject;
        root.name = SceneName;
        root.scene = this;
    }

    /**
     * Load all objects inside the specified folder in FilePath.Objects.
     * 
     * Params:
     *  objectPath =            The folder location inside of /Objects to look for objects in.
     */
    final void loadObjects( string objectPath = "" )
    {
        foreach( yml; loadYamlDocuments( buildNormalizedPath( FilePath.Resources.Objects, objectPath ) ) )
        {
            // Create the object
            root.addChild( GameObject.createFromYaml( yml ) );
        }
    }

    /**
     * Remove all objects from the collection.
     */
    final void clear()
    {
        root = new shared GameObject;
    }

    /**
    * TODO
    */
    final void update()
    {
        root.update();
    }

    /**
    * TODO
    */
    final void draw()
    {
        root.draw();
    }

    /**
    * TODO
    */
    final shared(GameObject) opIndex( string name )
    {
        if( auto id = name in idByName )
            return this[ *id ];
        else
            return null;
    }

    /**
    * TODO
    */
    final shared(GameObject) opIndex( uint index )
    {
        if( auto obj = index in objectById )
            return *obj;
        else
            return null;
    }

    /**
     * Adds object to the children, adds it to the scene graph.
     *
     * Params:
     *  newChild =            The object to add.
     */
    final void addChild( shared GameObject newChild )
    {
        root.addChild( newChild );
    }

    /**
    * TODO
    */
    final @property shared(GameObject[]) objects()
    {
        return objectById.values;
    }
}
