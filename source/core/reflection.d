module core.reflection;
import core;

/**
 * Meant to be added to members for making them YAML accessible.
 * Example:
 * ---
 * class Test : GameObject
 * {
 *     @Tweakable
 *     int x;
 * }
 * ---
 */
struct Tweakable
{

}

/**
 * Initializes reflection things.
 */
shared static this()
{
    foreach( mod; ModuleInfo )
    {
        foreach( klass; mod.localClasses )
        {
            // Find the appropriate game loop.
            if( klass.base == typeid(DGame) )
                DGame.instance = cast(shared DGame)klass.create();
        }
    }
}
