/**
 * Defines the DGame class, the base class for all game logic.
 */
module dash.core.dgame;
import dash;
import core.memory;

/**
 * The states the game can be in.
 */
enum EngineState
{
    /// The main game state.
    Run,
    /// In edit mode
    Editor,
    /// Refresh changed assets, but don't reset state.
    Refresh,
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
    bool autoRefresh;
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

    /// The editor controller, resolved by reflection.d
    Editor editor;

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
        start();

        GC.collect();

        // Loop until there is a quit message from the window or the user.
        while( currentState != EngineState.Quit )
        {
            // Frame Zone
            auto frameZone = DashProfiler.startZone( "Frame" );

            if( currentState == EngineState.Reset )
            {
                stop();
                start();
                GC.collect();
            }
            else if( currentState == EngineState.Refresh )
            {
                refresh();
            }

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
            if( stateFlags.updateUI )
            {
                auto uiUpdateZone = DashProfiler.startZone( "UI Update" );
                UserInterface.updateAwesomium();
            }

            // Update physics
            //if( stateFlags.updatePhysics )
            //  PhysicsController.stepPhysics( Time.deltaTime );

            if( stateFlags.updateTasks )
            {
                auto taskZone = DashProfiler.startZone( "Tasks" );
                executeTasks();
            }

            if( stateFlags.updateScene )
            {
                auto sceneUpdateZone = DashProfiler.startZone( "Scene Update" );
                activeScene.update();
            }

            // Do the updating of the child class.
            auto gameUpdateZone = DashProfiler.startZone( "Game Update" );
            onUpdate();
            gameUpdateZone.destroy();

            //////////////////////////////////////////////////////////////////////////
            // Draw
            //////////////////////////////////////////////////////////////////////////

            auto sceneDrawZone = DashProfiler.startZone( "Scene Draw" );
            activeScene.draw();
            sceneDrawZone.destroy();

            // Draw in child class
            auto gameDrawZone = DashProfiler.startZone( "Game Draw" );
            onDraw();
            gameDrawZone.destroy();

            // End drawing
            auto renderZone = DashProfiler.startZone( "Render" );
            Graphics.endDraw();
            renderZone.destroy();

            // Update the editor.
            auto editorUpdateZone = DashProfiler.startZone( "Editor Update" );
            editor.update();
            editorUpdateZone.destroy();

            // End the  frame zone.
            frameZone.destroy();

            // Update the profiler
            DashProfiler.update();
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
     * To be overridden, called when refreshing content.
     */
    void onRefresh() { }
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

        // This is so that the bench marks will log properly,
        // and config options will be update upon second call.
        DashLogger.setDefaults();

        bench!( { DashProfiler.initialize(); } )( "Profiler init" );
        bench!( { Config.initialize(); } )( "Config init" );
        bench!( { DashLogger.initialize(); } )( "Logger init" );
        bench!( { Input.initialize(); } )( "Input init" );
        bench!( { Graphics.initialize(); } )( "Graphics init" );
        bench!( { Assets.initialize(); } )( "Assets init" );
        bench!( { Audio.initialize(); } )( "Audio init" );
        bench!( { Prefabs.initialize(); } )( "Prefabs init" );
        bench!( { UserInterface.initializeAwesomium(); } )( "UI init" );
        bench!( { editor.initialize( this ); } )( "Editor init" );
        bench!( { DGame.instance.onInitialize(); } )( "Game init" );

        debug scheduleIntervaledTask( 1.seconds, { if( stateFlags.autoRefresh ) currentState = EngineState.Refresh; return false; } );
    }

    /**
     * Function called to shutdown controllers.
     */
    final void stop()
    {
        onShutdown();
        editor.shutdown();
        resetTasks();
        UserInterface.shutdownAwesomium();
        Assets.shutdown();
        Graphics.shutdown();
        Audio.shutdown();
    }

    /**
     * Reloads content and yaml.
     */
    final void refresh()
    {
        // Refresh
        Config.refresh();
        Assets.refresh();
        Graphics.refresh();
        Prefabs.refresh();
        activeScene.refresh();
        // Need to refresh key events.
        //Input.initialize();

        // Restart
        currentState = EngineState.Run;

        // Refresh game.
        onRefresh();
    }

    /**
     * Called when engine is resetting.
     */
    final void saveState()
    {
        onSaveState();
    }
}
