/**
 * This module defines the Scene class, 
 * 
 */
module core.scene;
import core, graphics, utility;

shared final class Scene
{
public:
    /// The AA of game objects managed.
    GameObject[string] objects;

    /// Allows functions to be called on this as if it were the AA.
    alias objects this;

    /**
     * Remove all objects from the collection.
     */
    final void clear()
    {
        foreach( key; objects.keys )
            objects.remove( key );
    }
}
