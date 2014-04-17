/**
 * Defines the DGame class, the base class for all game logic.
 */
module core.dgame;
import core, components, graphics, utility, deimos.cef3.app;

import std.string, std.datetime, std.parallelism, std.algorithm, std.traits;
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

shared struct UpdateFlags
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
        foreach( member; __traits(allMembers, UpdateFlags) )
            static if( __traits(compiles, __traits(getMember, UpdateFlags, member) = false) )
                __traits(getMember, UpdateFlags, member) = false;
    }

    /**
     * Set each member to true.
     */
    void resumeAll()
    {
        foreach( member; __traits(allMembers, UpdateFlags) )
            static if( __traits(compiles, __traits(getMember, UpdateFlags, member) = true) )
                __traits(getMember, UpdateFlags, member) = true;
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

    /// 
    UpdateFlags* updateFlags;

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

        cef_main_args_t mainArgs = {};
        mainArgs.instance = GetModuleHandle(NULL);
        
        // Application handler and its callbacks.
        // cef_app_t structure must be filled. It must implement
        // reference counting. You cannot pass a structure 
        // initialized with zeroes.
        cef_app_t app = {};
        initialize_app_handler(&app);
        
        // Execute subprocesses.
        printf("cef_execute_process, argc=%d\n", argc);
        int code = cef_execute_process(&mainArgs, &app, NULL);
        if (code >= 0) {
            _exit(code);
        }
        
        // Application settings.
        // It is mandatory to set the "size" member.
        cef_settings_t settings = {};
        settings.size = sizeof(cef_settings_t);
        settings.no_sandbox = 1;

        // Initialize CEF.
        printf("cef_initialize\n");
        cef_initialize(&mainArgs, &settings, &app, NULL);

        // Create GTK window. You can pass a NULL handle 
        // to CEF and then it will create a window of its own.
        //initialize_gtk();
        //GtkWidget* hwnd = create_gtk_window("cefcapi example", 1024, 768);
        //cef_window_info_t windowInfo = {};
        //windowInfo.parent_widget = hwnd;

        cef_window_info_t windowInfo = {};
        windowInfo.style = WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN \
                | WS_CLIPSIBLINGS | WS_VISIBLE;
        windowInfo.parent_window = NULL;
        windowInfo.x = CW_USEDEFAULT;
        windowInfo.y = CW_USEDEFAULT;
        windowInfo.width = CW_USEDEFAULT;
        windowInfo.height = CW_USEDEFAULT;

        // Initial url.
        char cwd[1024] = "";
        if (getcwd(cwd, sizeof(cwd)) == '\0') {
            printf("ERROR: getcwd() failed\n");
        }
        char url[1024];
        snprintf(url, sizeof(url), "file://%s/example.html", cwd);
        // There is no _cef_string_t type.
        cef_string_t cefUrl = {};
        cef_string_utf8_to_utf16(url, strlen(url), &cefUrl);
        
        // Browser settings.
        // It is mandatory to set the "size" member.
        cef_browser_settings_t browserSettings = {};
        browserSettings.size = sizeof(cef_browser_settings_t);
        
        // Client handler and its callbacks.
        // cef_client_t structure must be filled. It must implement
        // reference counting. You cannot pass a structure 
        // initialized with zeroes.
        cef_client_t client = {};
        initialize_client_handler(&client);

        // Create browser.
        printf("cef_browser_host_create_browser\n");
        cef_browser_host_create_browser(&windowInfo, &client, &cefUrl,
                &browserSettings, NULL);

        // Message loop.
        printf("cef_run_message_loop\n");
        cef_run_message_loop();

        // Shutdown CEF.
        printf("cef_shutdown\n");
        cef_shutdown();





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
            if ( updateFlags.updateUI )
            {
                UserInterface.updateAwesomium();
            }

            // Update physics
            //if( updateFlags.updatePhysics )
            //  PhysicsController.stepPhysics( Time.deltaTime );

            if ( updateFlags.updateTasks )
            {
                uint[] toRemove;    // Indicies of tasks which are done
                foreach( i, task; scheduledTasks )
                {
                    if( task() )
                        toRemove ~= cast(uint)i;
                }
                foreach( i; toRemove )
                {
                    // Get tasks after one being removed
                    auto end = scheduledTasks[ i+1..$ ];
                    // Get tasks before one being removed
                    scheduledTasks = scheduledTasks[ 0..i ];

                    // Allow data stomping
                    (cast(bool function()[])scheduledTasks).assumeSafeAppend();
                    // Add end back
                    scheduledTasks ~= end;
                }
            }

            if ( updateFlags.updateScene )
            {
                foreach( obj; activeScene )
                    obj.update();
            }

            // Do the updating of the child class.
            onUpdate();

            //////////////////////////////////////////////////////////////////////////
            // Draw
            //////////////////////////////////////////////////////////////////////////

            // Begin drawing
            Graphics.beginDraw();

            foreach( obj; activeScene )
                obj.draw();

            // Draw in child class
            onDraw();

            // End drawing
            Graphics.endDraw();
        }

        stop();
        */
    }

    /**
     * Schedule a task to be executed until it returns true.
     * 
     * Params:
     *  dg =                The task to execute
     */
    void scheduleTask( bool delegate() dg )
    {
        scheduledTasks ~= dg;
    }

    /**
     * Schedule a task to be executed until the duration expires.
     * 
     * Params:
     *  dg =                The task to execute
     *  duration =          The duration to execute the task for
     */
    void scheduleTimedTask( void delegate() dg, Duration duration )
    {
        auto startTime = Time.totalTime;
        scheduleTask( {
            dg();
            return Time.totalTime >= startTime + duration;
        } );
    }

    //static Camera camera;

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
    /// The tasks that have been scheduled
    bool delegate()[] scheduledTasks;

    /**
     * Function called to initialize controllers.
     */
    final void start()
    {
        currentState = EngineState.Run;

        updateFlags = new shared UpdateFlags;
        updateFlags.resumeAll();

        logInfo( "Initializing..." );
        auto start = Clock.currTime;
        auto subStart = start;

        Config.initialize();
        Input.initialize();
        Output.initialize();

        logInfo( "Graphics initialization:" );
        subStart = Clock.currTime;
        Graphics.initialize();
        logInfo( "Graphics init time: ", Clock.currTime - subStart );

        logInfo( "Assets initialization:" );
        subStart = Clock.currTime;
        Assets.initialize();
        logInfo( "Assets init time: ", Clock.currTime - subStart );

        Prefabs.initialize();

        UserInterface.initializeCEF();

        //Physics.initialize();

        onInitialize();

        logInfo( "Total init time: ", Clock.currTime - start );
    }

    /**
     * Function called to shutdown controllers.
     */
    final void stop()
    {
        onShutdown();
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
