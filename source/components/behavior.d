/**
 * Defines Behavior class, the base class for all scripts.
 */
module components.behavior;
import utility;

import yaml;
import std.algorithm, std.array;

/**
 * Defines methods for child classes to override.
 */
private abstract shared class ABehavior
{
    protected void initializeBehavior( Object param ) {  }
    /// Called on the update cycle.
    void onUpdate() { }
    /// Called on the draw cycle.
    void onDraw() { }
    /// Called on shutdown.
    void onShutdown() { }
}

/**
 * Defines methods for child classes to override, with a parameter for onInitialize.
 *
 * Params:
 *  InitType =          The type for onInitialize to take.
 */
abstract shared class Behavior( InitType = void ) : ABehavior
{
    static if( is( InitType == void ) )
    {
        void onInitialize() { }
    }
    else
    {
        void onInitialize( InitType ) { }
        private final override initializeBehavior( Object param )
        {
            onInitialize( cast(InitType)param );
        }
    }

    /**
     * Registers subclasses with onInit function pointers/
     */
    shared static this()
    {
        static if( !is( InitType == void ) )
        {
            foreach( mod; ModuleInfo )
            {
                foreach( klass; mod.localClasses )
                {
                    if( klass.base == typeid(Behavior!T) )
                    {
                        getInitParams[ klass.name ] = &Config.getObject!T;
                    }
                }
            }
        }
    }
}

private shared Object function( Node )[string] getInitParams;

/**
 * Defines a collection of Behaviors to allow for multiple scripts to be added to an object.
 */
final shared class Behaviors
{
private:
    ABehavior[] behaviors;

public:
    /**
     * Adds a new behavior to the collection.
     *
     * Params:
     *  newBehavior =   The behavior to add to the object.
     */
    void createBehavior( string className, Node fields = Node( YAMLNull() ) )
    {
        auto newBehavior = cast(shared ABehavior)Object.factory( className );

        if( !newBehavior )
        {
            logWarning( "Class ", className, " either not found or not child of Behavior." );
            return;
        }

        if( !fields.isNull && className in getInitParams )
        {
            newBehavior.initializeBehavior( getInitParams[ className ]( fields ) );
        }
        else
        {
            newBehavior.initializeBehavior( null );
        }

        behaviors ~= newBehavior;
    }

    mixin( callBehaviors );
}

enum callBehaviors = "".reduce!( ( a, func ) => a ~
    q{
        void $func()
        {
            foreach( script; behaviors )
                script.$func();
        }
    }.replace( "$func", func ) )( ( cast(string[])[__traits( derivedMembers, ABehavior )] )[ 1..$ ] );
