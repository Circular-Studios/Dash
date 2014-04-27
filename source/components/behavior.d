/**
 * Defines Behavior class, the base class for all scripts.
 */
module components.behavior;
import core, utility;

import yaml;
import std.algorithm, std.array, std.traits;

/**
 * Defines methods for child classes to override.
 */
private abstract shared class ABehavior
{
    /// The object the behavior belongs to.
    private GameObject _owner;
    /// Function called by Behaviors to init the object.
    /// Should not be touched by anything outside this module.
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
        /**
         * The function called on initialization of the object.
         */
        void onInitialize() { }
        protected final override void initializeBehavior( Object param ) { onInitialize(); }
    }
    else
    {
        /**
         * The function called on initialization of the object.
         *
         * Params:
         *  arg =       The args defined by the object.
         */
        void onInitialize( InitType arg ) { }
        protected final override void initializeBehavior( Object param )
        {
            onInitialize( cast(InitType)param );
        }
    }

    /// Returns the GameObject which owns this behavior.
    mixin( Getter!_owner );

    /**
     * Registers subclasses with onInit function pointers.
     */
    shared static this()
    {
        static if( !is( InitType == void ) )
        {
            foreach( mod; ModuleInfo )
            {
                foreach( klass; mod.localClasses )
                {
                    if( klass.base == typeid(Behavior!InitType) )
                    {
                        getInitParams[ klass.name ] = &Config.getObject!InitType;
                        return;
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
    void createBehavior( shared GameObject owner, string className, Node fields = Node( YAMLNull() ) )
    {
        auto newBehavior = cast(shared ABehavior)Object.factory( className );
        newBehavior._owner = owner;

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
            static if( __traits( compiles, ParameterTypeTuple!( __traits( getMember, "$func") ) ) &&
                        ParameterTypeTuple!( __traits( getMember, "$func") ).length == 0 )
            {
                foreach( script; behaviors )
                {
                    script.$func();
                }
            }
        }
    }.replace( "$func", func ) )( cast(string[])[__traits( derivedMembers, ABehavior )] );
