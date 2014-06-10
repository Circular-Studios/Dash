/**
 * Contains Prefabs and Prefab, manages creation and management of prefabs.
 */
module dash.core.prefabs;
import dash.core, dash.components, dash.utility;

import yaml;
import gl3n.linalg;
import std.variant;

mixin( registerComponents!q{core.prefabs} );

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
            
            //auto newFab = new Prefab( object );
            auto newFab = cast(Prefab)createYamlObject[ "Prefab" ]( object );
            newFab.name = name;
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
            node => cast(Prefab)createYamlObject[ "Prefab" ]( node ),
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
@yamlObject()
final class Prefab : YamlObject
{
public:
    /// The name of the prefab.
    mixin( Property!_name );

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
    string _name;
}
