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
final class Scene
{
private:
    GameObject _root;

package:
    GameObject[uint] objectById;
    uint[string] idByName;

public:
    /// The camera to render with.
    Camera camera;
    /// The root object of the scene.
    mixin( Getter!_root );

    this()
    {
        _root = new GameObject;
        _root.name = SceneName;
        _root.scene = this;
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
            _root.addChild( GameObject.createFromYaml( yml ) );
        }
    }

    /**
     * Remove all objects from the collection.
     */
    final void clear()
    {
        _root = new GameObject;
    }

    /**
     * Updates all objects in the scene.
     */
    final void update()
    {
        _root.update();
    }

    /**
     * Draws all objects in the scene.
     */
    final void draw()
    {
        _root.draw();
    }

    /**
     * Gets the object in the scene with the given name.
     *
     * Params:
     *  name =            The name of the object to look for.
     *
     * Returns: The object with the given name.
     */
    final GameObject opIndex( string name )
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
    final GameObject opIndex( uint index )
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
    final void addChild( GameObject newChild )
    {
        _root.addChild( newChild );
    }

    /**
     * Removes the given object as a child from this scene.
     *
     * Params:
     *  oldChild =            The object to remove.
     */
    final void removechild( GameObject oldChild )
    {
        _root.removeChild( oldChild );
    }

    /**
     * Gets all objects in the scene.
     *
     * Returns: All objects belonging to this scene.
     */
    final @property GameObject[] objects()
    {
        return objectById.values;
    }
}
