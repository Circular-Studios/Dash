/**
 * This module defines the Scene class, TODO
 *
 */
module core.scene;
import core, components, graphics, utility;

import std.path;

enum SceneName = "[scene]";

/**
 * The Scene contains a list of all objects that should be drawn at a given time.
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
     * Updates all objects in the scene.
     */
    final void update()
    {
        root.update();
    }

    /**
     * Draws all objects in the scene.
     */
    final void draw()
    {
        root.draw();
    }

    /**
     * Gets the object in the scene with the given name.
     *
     * Params:
     *  name =            The name of the object to look for.
     *
     * Returns: The object with the given name.
     */
    final shared(GameObject) opIndex( string name )
    {
        if( auto id = name in idByName )
            return this[ *id ];
        else
            return null;
    }

    /**
     * Gets the object in the scene with the given id.
     *
     * Params:
     *  index =           The id of the object to look for.
     *
     * Returns: The object with the given id.
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
     * Removes the given object as a child from this scene.
     *
     * Params:
     *  oldChild =            The object to remove.
     */
    final void removechild( shared GameObject oldChild )
    {
        root.removeChild( oldChild );
    }

    /**
     * Gets all objects in the scene.
     *
     * Returns: All objects belonging to this scene.
     */
    final @property shared(GameObject[]) objects()
    {
        return objectById.values;
    }
}
