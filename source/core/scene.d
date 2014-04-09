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
    /// The camera to render with.
    Camera camera;

    this()
    {
        root = new shared GameObject;
    }

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
            root.addChild( GameObject.createFromYaml( yml, parents, children ) );
        }
        
        // Make sure the child graph is complete.
        foreach( object, parentName; parents )
            this[ parentName ].addChild( object );
        foreach( object, childNames; children )
            foreach( child; childNames )
                object.addChild( this[ child ] );
    }

    /**
     * Remove all objects from the collection.
     */
    final void clear()
    {
        root = new shared GameObject;
    }

    final void update()
    {
        root.update();
    }

    final void draw()
    {
        root.draw();
    }

    final shared(GameObject) opIndex( string name )
    {
        shared GameObject[] objs;

        objs ~= root;

        while( objs.length )
        {
            auto curObj = objs[ 0 ];
            objs = objs[ 1..$ ];

            if( curObj.name == name )
                return curObj;
            else
                foreach( obj; curObj.children )
                    objs ~= obj;
        }

        return null;
    }

    final shared(GameObject) opIndex( size_t index )
    {
        return null;
    }

    final @property shared(GameObject[]) objects()
    {
        shared GameObject[] objs, toReturn;

        objs ~= root;

        while( objs.length )
        {
            toReturn ~= objs[ 0 ].children;
            objs = objs[ 1..$ ];
        }

        return toReturn;
    }

private:
    GameObject root;
}
