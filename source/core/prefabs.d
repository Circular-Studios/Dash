/**
 * Contains Prefabs and Prefab, manages creation and management of prefabs.
 */
module core.prefabs;
import core, components, utility;

import yaml;
import gl3n.linalg;
import std.variant;

/**
 * Prefabs manages prefabs and allows access to them.
 */
final abstract class Prefabs
{
static:
public:
    /// The AA of prefabs.
    Prefab[string] prefabs;

    /// Allows functions to be called on this like it were the AA.
    alias prefabs this;

    /**
     * Load and initialize all prefabs in FilePath.Resources.Prefabs.
     */
    void initialize()
    {
        foreach( key; prefabs.keys )
            prefabs.remove( key );

        foreach( objFile; loadYamlFiles( Resources.Prefabs ) )
        {
            auto object = objFile[0];
            auto name = object[ "Name" ].as!string;
            
            auto newFab = new Prefab( object );
            prefabs[ name ] = newFab;
            prefabResources[ objFile[1] ] ~= newFab;
        }
    }

    /**
     * Refreshes prefabs that are outdated.
     */
    void refresh()
    {
        refreshYamlObjects!(
            node => new Prefab( node ),
            node => node[ "Name" ].get!string in prefabs,
            ( node, fab ) => prefabs[ node[ "Name" ].get!string ] = fab,
            fab => prefabs.remove( fab.name ) )
                ( prefabResources );
    }

private:
    Prefab[][Resource] prefabResources;
}

/**
 * A prefab that allows for quick object creation.
 */
final class Prefab
{
public:
    /// The name of the prefab.
    mixin( Getter!_name );

    /**
     * Create a prefab from a YAML node.
     * 
     * Params:
     *  yml =           The YAML node to get info from.
     */
    this( Node yml )
    {
        refresh( yml );
        this._name = yml[ "Name" ].get!string;
    }

    /**
     * Refreshes the makeup of the prefab.
     *
     * Params:
     *  yml =           The new yaml for the prefab.
     */
    void refresh( Node yml )
    {
        this.yaml = yml;
    }

    /**
     * Creates a GameObject instance from the prefab.
     *
     * Returns:
     *  The new GameObject from the Prefab.
     */
    GameObject createInstance()
    {
        return GameObject.createFromYaml( yaml );
    }

private:
    immutable string _name;
    Node yaml;
}
