/**
 * Defines the DGame class, the base class for all game logic.
 */
module core.dgame;
import core, components, graphics, utility, utility.awesomium;

/**
 * The states the game can be in.
 */
enum EngineState
{
    /// The main game state.
    Run,
    /// Reload all assets at the beginning of the next cycle.
    Reset,
    /// Quit the game and the end of this cycle.
    Quit
}

/**
 * Contains flags for all things that could be disabled.
 */
struct GameStateFlags
{
    bool updateScene;
    bool updateUI;
    bool updateTasks;
    //bool updatePhysics;

    /**
     * Set each member to false.
     */
    void pauseAll()
    {
        foreach( member; __traits(allMembers, GameStateFlags) )
            static if( __traits(compiles, __traits(getMember, GameStateFlags, member) = false) )
                __traits(getMember, GameStateFlags, member) = false;
    }

    /**
     * Set each member to true.
     */
    void resumeAll()
    {
        foreach( member; __traits(allMembers, GameStateFlags) )
            static if( __traits(compiles, __traits(getMember, GameStateFlags, member) = true) )
                __traits(getMember, GameStateFlags, member) = true;
    }
}

/**
 * The main game loop manager. Meant to be overridden.
 */
class DGame
{
public:
    /// The instance to be running from
    static DGame instance;

    /// Current state of the game
    EngineState currentState;

    /// The current update settings
    GameStateFlags* stateFlags;

    /// The currently active scene
    Scene activeScene;

    /**
     * Overrideable. Returns the name of the window.
     */
    @property string title()
    {
        return "Dash";
    }

    /**
     * Main Game loop.
     */
    final void run()
    {

        // Init tasks
        //TaskManager.initialize();
        start();

        // Loop until there is a quit message from the window or the user.
        while( currentState != EngineState.Quit )
        {
            if( currentState == EngineState.Reset )
                reload();

            //////////////////////////////////////////////////////////////////////////
            // Update
            //////////////////////////////////////////////////////////////////////////

            // Platform specific program stuff
            Graphics.messageLoop();

            // Update time
            Time.update();

            // Update input
            Input.update();

            // Update webcore
            if ( stateFlags.updateUI )
            {
                UserInterface.updateAwesomium();
            }

            // Update physics
            //if( stateFlags.updatePhysics )
            //  PhysicsController.stepPhysics( Time.deltaTime );

            if ( stateFlags.updateTasks )
            {
                executeTasks();
            }

            if ( stateFlags.updateScene )
            {
                activeScene.update();
            }

            // Do the updating of the child class.
            onUpdate();

            //////////////////////////////////////////////////////////////////////////
            // Draw
            //////////////////////////////////////////////////////////////////////////

            // Begin drawing
            Graphics.beginDraw();

            activeScene.draw();

            // Draw in child class
            onDraw();

            // End drawing
            Graphics.endDraw();
        }

        stop();
    }

protected:
    /**
     * To be overridden, logic for when the game is being initalized.
     */
    void onInitialize() { }
    /**
     * To be overridden, called once per frame during the update cycle.
     */
    void onUpdate() { }
    /**
     * To be overridden, called once per frame during the draw cycle.
     */
    void onDraw() { }
    /**
     * To be overridden, called when the came is closing.
     */
    void onShutdown() { }
    /**
     * To be overridden, called when resetting and the state must be saved.
     */
    void onSaveState() { }

private:
    /**
     * Function called to initialize controllers.
     */
    final void start()
    {
        currentState = EngineState.Run;

        stateFlags = new GameStateFlags;
        stateFlags.resumeAll();

        logDebug( "Initializing..." );
        bench!( { Config.initialize(); } )( "Config init" );
        bench!( { Logger.initialize(); } )( "Logger init" );
        bench!( { Input.initialize(); } )( "Input init" );
        bench!( { Graphics.initialize(); } )( "Graphics init" );
        bench!( { Assets.initialize(); } )( "Assets init" );
        bench!( { Prefabs.initialize(); } )( "Prefabs init" );
        bench!( { UserInterface.initializeAwesomium(); } )( "UI init" );
        bench!( { DGame.instance.onInitialize(); } )( "Game init" );
    }

    /**
     * Function called to shutdown controllers.
     */
    final void stop()
    {
        onShutdown();
        resetTasks();
        UserInterface.shutdownAwesomium();
        Assets.shutdown();
        Graphics.shutdown();
    }

    /**
     * Reloads content and yaml.
     */
    final void reload()
    {
        // Shut everything down
        //onShutdown();
        //resetTasks();
        //UserInterface.shutdownAwesomium();
        //Graphics.shutdown();

        // Refresh
        Config.refresh();
        Assets.refresh();
        Graphics.reload();

        // Restart
        currentState = EngineState.Run;

        /*stateFlags = new GameStateFlags;
        stateFlags.resumeAll();

        logDebug( "Initializing..." );
        bench!( { Logger.initialize(); } )( "Logger init" );
        bench!( { Input.initialize(); } )( "Input init" );
        bench!( { Graphics.initialize(); } )( "Graphics init" );
        bench!( { Prefabs.initialize(); } )( "Prefabs init" );
        bench!( { UserInterface.initializeAwesomium(); } )( "UI init" );
        bench!( { DGame.instance.onInitialize(); } )( "Game init" );*/
    }

    /**
     * Called when engine is resetting.
     */
    final void saveState()
    {
        onSaveState();
    }
}
