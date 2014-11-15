/**
 * This module defines the Scene class, TODO
 *
 */
module dash.core.scene;
import dash.core, dash.components, dash.graphics, dash.utility;

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
    Listener listener;
	UserInterface ui;

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
        foreach( file; buildNormalizedPath( Resources.Objects, objectPath ).scanDirectory() )
        {
            // Create the objects
            foreach( desc; file.deserializeMultiFile!( GameObject.Description )() )
            {
                auto newObj = GameObject.create( desc );
                _root.addChild( newObj );
                objectsByResource[ file ] ~= GameObjectResource( file, newObj );
            }
        }
    }

    /**
     * Remove all objects from the collection.
     */
    final void clear()
    {
        _root.shutdown();
        destroy( _root );
        _root = new GameObject;

        if( ui )
        {
            ui.shutdown();
            destroy( ui );
            // TODO: Can be built automatically by config
            ui = null;
        }
    }

    /**
     * Updates all objects in the scene.
     */
    final void update()
    {
        if( ui )
            ui.update();
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
     * Refreshes all objects in the scene that need refreshing.
     */
    final void refresh()
    {
        // Iterate over each file, and it's objects
        foreach_reverse( file; objectsByResource.keys )
        {
            auto objReses = objectsByResource[ file ];

            if( file.exists() )
            {
                if( file.needsRefresh() )
                {
                    auto descs = deserializeMultiFile!( GameObject.Description )( file );
                    assert( descs.length == objReses.length, "Adding or removing objects from a file is currently unsupported." );

                    foreach( i, objRes; objReses )
                    {
                        objRes.object.refresh( descs[ i ] );
                    }
                }
            }
            else
            {
                foreach( objRes; objReses )
                {
                    objRes.object.shutdown();
                    removeChild( objRes.object );
                }

                objectsByResource.remove( file );
            }
        }
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
    final void removeChild( GameObject oldChild )
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
