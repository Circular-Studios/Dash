/**
 * Contains Prefabs and Prefab, manages creation and management of prefabs.
 */
module core.prefabs;
import core, components, utility;

import yaml;
import gl3n.linalg;
import std.variant;

PrefabManager Prefabs;

static this()
{
    Prefabs = new PrefabManager;
}

/**
 * Prefabs manages prefabs and allows access to them.
 */
final class PrefabManager
{
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

        foreach( object; loadYamlDocuments( FilePath.Resources.Prefabs ) )
        {
            auto name = object[ "Name" ].as!string;
            
            prefabs[ name ] = new Prefab( object );
        }
    }
}

/**
 * A prefab that allows for quick object creation.
 */
final class Prefab
{
public:
    /**
     * Create a prefab from a YAML node.
     * 
     * Params:
     *  yml =           The YAML node to get info from.
     */
    this( Node yml )
    {
        this.yaml = yml;
    }

    /**
     * Creates a GameObject instance from the prefab.
     * 
     * Params:
     *  scriptOverride =            Create the instance from this class type instead of the prefab's default.
     *
     * Returns:
     *  The new GameObject from the Prefab.
     */
    final GameObject createInstance()
    {
        return GameObject.createFromYaml( yaml );
    }

private:
    immutable Node yaml;
}
