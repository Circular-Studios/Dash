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
private abstract class ABehavior
{
    /// The object the behavior belongs to.
    private GameObject _owner;
    /// Function called by Behaviors to init the object.
    /// Should not be touched by anything outside this module.
    protected void initializeBehavior( Object param ) { }
    /// The function called on initialization of the object.
    void onInitialize() { }
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
abstract class Behavior( InitType = void ) : ABehavior
{
    static if( !is( InitType == void ) )
    {
        InitType initArgs;
        protected final override void initializeBehavior( Object param )
        {
            initArgs = cast(InitType)param;
        }
    }

    /// Returns the GameObject which owns this behavior.
    mixin( Getter!_owner );

    /**
     * Registers subclasses with onInit function pointers.
     */
    static this()
    {
        static if( !is( InitType == void ) )
        {
            foreach( mod; ModuleInfo )
            {
                foreach( klass; mod.localClasses )
                {
                    if( klass.base == typeid(Behavior!InitType) )
                    {
                        getInitParams[ klass.name ] = &getObject!InitType;
                    }
                }
            }
        }
    }
}

private Object function( Node )[string] getInitParams;

/**
 * Defines a collection of Behaviors to allow for multiple scripts to be added to an object.
 */
struct Behaviors
{
private:
    ABehavior[] behaviors;
    GameObject _owner;

public:
    /**
     * Constructor for Behaviors which assigns its owner.
     *
     * Params:
     *  owner =         The owner of this behavior set.
     */
    this( GameObject owner )
    {
        _owner = owner;
    }

    /**
     * Adds a new behavior to the collection.
     *
     * Params:
     *  className =     The behavior to add to the object.
     *  fields =        Fields to convert give to behavior
     */
    ABehavior createBehavior( string className, Node fields = Node( YAMLNull() ) )
    {
        auto newBehavior = cast(ABehavior)Object.factory( className );
        newBehavior._owner = _owner;

        if( !newBehavior )
        {
            logWarning( "Class ", className, " either not found or not child of Behavior." );
            return null;
        }

        newBehavior._owner = _owner;

        if( !fields.isNull && className in getInitParams )
        {
            newBehavior.initializeBehavior( getInitParams[ className ]( fields ) );
        }

        behaviors ~= newBehavior;

        return newBehavior;
    }

    /**
     * Adds a new behavior to the collection.
     *
     * Params:
     *  T =             The behavior to add to the object.
     *  fields =        Fields to convert give to behavior
     */
    T createBehavior( T )( Node fields = Node( YAMLNull() ) ) if( is( T : ABehavior ) )
    {
        auto newBehavior = new T;

        if( !newBehavior )
        {
            logWarning( "Class ", T.stringof, " either not found or not child of Behavior." );
            return null;
        }

        newBehavior._owner = _owner;

        if( !fields.isNull && T.stringof in getInitParams )
        {
            newBehavior.initializeBehavior( getInitParams[ T.stringof ]( fields ) );
        }

        behaviors ~= newBehavior;

        return newBehavior;
    }

    /**
     * Gets the behavior of the given type.
     *
     * Returns: The bahavior
     */
    BehaviorType get( BehaviorType = ABehavior )()
    {
        foreach( behav; behaviors )
        {
            if( typeid(behav) == typeid(BehaviorType) )
                return cast(BehaviorType)behav;
        }

        return null;
    }

    mixin( callBehaviors );
}

enum callBehaviors = "".reduce!( ( a, func ) => a ~
    q{
        static if( __traits( compiles, ParameterTypeTuple!( __traits( getMember, ABehavior, "$func") ) ) &&
                    ParameterTypeTuple!( __traits( getMember, ABehavior, "$func") ).length == 0 )
        {
            void $func()
            {
                foreach( script; behaviors )
                {
                    script.$func();
                }
            }
        }
    }.replace( "$func", func ) )( cast(string[])[__traits( derivedMembers, ABehavior )] );
