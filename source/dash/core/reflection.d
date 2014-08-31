module dash.core.reflection;
import dash.core;

/**
 * Initializes reflection things.
 */
static this()
{
    foreach( mod; ModuleInfo )
    {
        foreach( klass; mod.localClasses )
        {
            // Find the appropriate game loop.
            if( klass.base == typeid(DGame) )
                DGame.instance = cast(DGame)klass.create();
        }
    }
}
