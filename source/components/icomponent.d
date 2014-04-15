/**
 * Defines the Component abstract class, which is the base for all components.
 */
module components.icomponent;
import core, graphics;

import yaml;

/**
 * Interface for components to implement.
 */
shared interface IComponent
{
private:
    shared static GameObject[ shared IComponent ] owners;
public:
    /**
     * Functions to call when creating components.
     */
    static shared(IComponent) function( Node, shared GameObject )[string] initializers;

    /**
     * The GameObject that owns this component.
     */
    final @property shared(GameObject) owner()
    {
        auto owner = this in owners;
        if( owner )
            return *owner;
        else
            return null;
    }

    /// ditto
    final @property void owner( shared GameObject newOwner )
    {
        owners[ this ] = newOwner;
    }

    /**
     * Function called on update.
     */
    void update();
    
    /**
     * Function called on shutdown.
     */
    void shutdown();
}
