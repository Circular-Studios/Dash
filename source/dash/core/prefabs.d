/**
 * Contains Prefabs and Prefab, manages creation and management of prefabs.
 */
module dash.core.prefabs;
import dash.core, dash.components, dash.utility;

mixin( registerComponents!() );

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

    // Not sure what this is all about, but opIndex no longer forwards as of 2.066.
    static if( __VERSION__ > 2065 )
    {
        Prefab opIndex( string index )
        {
            if( auto fab = index in prefabs )
            {
                return *fab;
            }
            else
            {
                warningf( "Prefab %s not found.", index );
                return null;
            }
        }

        Prefab opIndexAssign( Prefab newFab, string index )
        {
            prefabs[ index ] = newFab;
            return newFab;
        }
    }

    /**
     * Load and initialize all prefabs in FilePath.Resources.Prefabs.
     */
    void initialize()
    {
        foreach( key; prefabs.keys )
            prefabs.remove( key );

        foreach( res; scanDirectory( Resources.Prefabs ) )
        {
            foreach( fabDesc; res.deserializeMultiFile!( GameObject.Description )() )
            {
                auto newFab = new Prefab( fabDesc, res );
                prefabs[ newFab.name ] = newFab;
                prefabResources[ res ] ~= newFab;
            }
        }
    }

    /**
     * Refreshes prefabs that are outdated.
     */
    void refresh()
    {
        //TODO: Implement
    }

private:
    Prefab[][Resource] prefabResources;
}

/**
 * A prefab that allows for quick object creation.
 */
final class Prefab : Asset
{
public:
    /// The name of the prefab.
    const(string) name() @property
    {
        return description.name;
    }
    /// The description to create objects from.
    GameObject.Description description;

    /// Creates a prefab from a description.
    this( GameObject.Description desc, Resource filePath )
    {
        description = desc;
        super( filePath );
    }

    /**
     * Creates a GameObject instance from the prefab.
     *
     * Returns:
     *  The new GameObject from the Prefab.
     */
    GameObject createInstance() const
    {
        return GameObject.create( description );
    }
}
