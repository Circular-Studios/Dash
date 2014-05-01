/**
 * Defines the DGame class, the base class for all game logic.
 */
module core.dgame;
import core, components, graphics, utility, deimos.cef3.app, deimos.cef3.client, deimos.cef3.browser, deimos.cef3.render_handler;

import std.string, std.datetime, std.parallelism, std.algorithm, std.traits, std.stdio;
public import core.time;
import win32.windows;

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
shared struct GameStateFlags
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
shared class DGame
{
public:
    /// The instance to be running from
    shared static DGame instance;

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
        import std.c.stdio;
        /*
        cef_main_args_t mainArgs = {};
        mainArgs.instance = GetModuleHandle(NULL);
        
        // Application handler and its callbacks.
        // cef_app_t structure must be filled. It must implement
        // reference counting. You cannot pass a structure 
        // initialized with zeroes.
        cef_app_t app = {};

        printf("initialize_app_handler\n");
        app.base.size = cef_app_t.sizeof;

        printf("initialize_cef_base\n");
        // Check if "size" member was set.
        size_t size = app.base.size;
        // Let's print the size in case sizeof was used
        // on a pointer instead of a structure. In such
        // case the number will be very high.
        printf("cef_base_t.size = %lu\n", cast(ulong)size);
        if (size <= 0) {
            printf("FATAL: initialize_cef_base failed, size member not set\n");
            stop();
        }
        


        // Execute subprocesses.
        //printf("cef_execute_process, argc=%d\n", argc);
        int code = cef_execute_process(&mainArgs, &app, NULL);
        if (code >= 0) {
            stop();
        }
        
        // Application settings.
        // It is mandatory to set the "size" member.
        cef_settings_t settings = {};
        settings.size = cef_settings_t.sizeof;
        settings.no_sandbox = 1;
        settings.windowless_rendering_enabled = 1;
        //settings.multi_threaded_message_loop = 0;


        // Initialize CEF.
        printf("cef_initialize\n");
        cef_initialize(&mainArgs, &settings, &app, NULL);
        */
        cef_render_handler_t cefRenderHandler = {};


        // Create GTK window. You can pass a NULL handle 
        // to CEF and then it will create a window of its own.
        //initialize_gtk();
        //GtkWidget* hwnd = create_gtk_window("cefcapi example", 1024, 768);
        //cef_window_info_t windowInfo = {};
        //windowInfo.parent_widget = hwnd;

        cef_window_info_t windowInfo = {};
        //windowInfo.style = WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN | WS_CLIPSIBLINGS | WS_VISIBLE;
        // TODO: Ensure parent_window does not need to be set (takes hWnd)
        windowInfo.parent_window = Win32.get.hWnd;
        windowInfo.x = 0;
        windowInfo.y = 0;
        windowInfo.width = Graphics.width;
        windowInfo.height = Graphics.height;
        // Enable offscreen rendering
        windowInfo.windowless_rendering_enabled = 1;
        windowInfo.transparent_painting_enabled = 1;

        // Create url to display
        cef_string_t cefUrl = {};

        immutable(cef_char_t)[] url = "http://www.google.com" ~ "\0";
        //cef_string_utf16_set(url.ptr, url.length, &cefUrl, 0);

        cefUrl.str = url.dup.ptr;
        cefUrl.length = url.length;
        //printf("%d\n", url.length);
        //writef("%s\n", url);
        //writef("%s\n", cefUrl.str);
        //writef("%s\n", cefUrl.str[0..url.length]);
        
        
        // Browser settings.
        // It is mandatory to set the "size" member.
        cef_browser_settings_t browserSettings = {};
        browserSettings.size = cef_browser_settings_t.sizeof;
        
        // Client handler and its callbacks.
        // cef_client_t structure must be filled. It must implement
        // reference counting. You cannot pass a structure 
        // initialized with zeroes.
        cef_client_t client = {};
        client.get_context_menu_handler = ( cef_client_t* self ) { };
        client.get_drag_handler = self => new cef_drag_handler_t;
        

        printf("initialize_client_handler\n");
        client.base.size = cef_client_t.sizeof;
        
        printf("initialize_cef_base\n");
        // Check if "size" member was set.
        size_t size2 = client.base.size;
        // Let's print the size in case sizeof was used
        // on a pointer instead of a structure. In such
        // case the number will be very high.
        printf("cef_base_t.size = %lu\n", cast(ulong)size2);
        if (size2 <= 0) {
            printf("FATAL: initialize_cef_base failed, size member not set\n");
            stop();
        }

        // Create browser.
        printf("cef_browser_host_create_browser\n");
        cef_browser_host_create_browser(&windowInfo, &client, &cefUrl,
                &browserSettings, NULL);


        //writef("Get URL\n");


        //writef("%s\n", cefUrl.str[0..url.length]);



        /*
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
        */
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

        stateFlags = new shared GameStateFlags;
        stateFlags.resumeAll();

        logDebug( "Initializing..." );
        bench!( { Config.initialize(); } )( "Config init" );
        bench!( { Logger.initialize(); } )( "Logger init" );
        bench!( { Input.initialize(); } )( "Input init" );
        bench!( { Graphics.initialize(); } )( "Graphics init" );
        bench!( { Assets.initialize(); } )( "Assets init" );
        bench!( { Prefabs.initialize(); } )( "Prefabs init" );
        bench!( { UserInterface.initializeCEF(); } )( "UI init" );
        bench!( { DGame.instance.onInitialize(); } )( "Game init" );
    }

    /**
     * Function called to shutdown controllers.
     */
    final void stop()
    {
        onShutdown();
		resetTasks();
        UserInterface.shutdownCEF();
        Assets.shutdown();
        Graphics.shutdown();
    }

    /**
     * Reloads content and yaml.
     */
    final void reload()
    {
        stop();

        start();
    }

    /**
     * Called when engine is resetting.
     */
    final void saveState()
    {
        onSaveState();
    }
}
