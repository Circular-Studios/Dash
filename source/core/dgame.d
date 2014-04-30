/**
 * Defines the DGame class, the base class for all game logic.
 */
module core.dgame;
import core, components, graphics, utility, deimos.cef3.app, deimos.cef3.client, deimos.cef3.browser;

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
        
        cef_main_args_t mainArgs = {};
        mainArgs.instance = GetModuleHandle(NULL);
        
        // Application handler and its callbacks.
        // cef_app_t structure must be filled. It must implement
        // reference counting. You cannot pass a structure 
        // initialized with zeroes.
        cef_app_t app = {};

        ///
        //BEGIN initialize_app_handler(&app);
        ///
        printf("initialize_app_handler\n");
        app.base.size = cef_app_t.sizeof;

        ///
        //BEGIN initialize_cef_base(cast(cef_base_t*)app);
        ///
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
        /*
        app.base.add_ref = add_ref;
        app.base.release = release;
        app.base.get_refct = get_refct;
        */
        ///
        //END initialize_cef_base(cast(cef_base_t*)app);
        ///


        // callbacks
        /*
        app.on_before_command_line_processing = on_before_command_line_processing;
        app.on_register_custom_schemes = on_register_custom_schemes;
        app.get_resource_bundle_handler = get_resource_bundle_handler;
        app.get_browser_process_handler = get_browser_process_handler;
        app.get_render_process_handler = get_render_process_handler;
        */
        ///
        // END initialize_app_handler(&app)
        ///
        


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
        windowInfo.style = WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN | WS_CLIPSIBLINGS | WS_VISIBLE;
        windowInfo.parent_window = NULL;
        windowInfo.x = CW_USEDEFAULT;
        windowInfo.y = CW_USEDEFAULT;
        windowInfo.width = CW_USEDEFAULT;
        windowInfo.height = CW_USEDEFAULT;

        // Initial url.
        //char cwd[1024] = "";
        /*
        if (getcwd(cwd, cwd.sizeof) == '\0') {
            printf("ERROR: getcwd() failed\n");
        }
        */
        //char url[1024];
        //snprintf(url, url.sizeof, "file://%s/example.html", cwd);
        // There is no _cef_string_t type.


        cef_string_t cefUrl = {};

        //wchar[] url = "http://www.google.com";
        //wstring wurl = "http://www.google.com";
        //wchar* url = toStringz(wurl);



        immutable(cef_char_t)[] url = "http://www.google.com" ~ "\0";
        //cef_string_utf16_set(url.ptr, url.length, &cefUrl, 0);

        cefUrl.str = url.dup.ptr;
        cefUrl.length = url.length;


        printf("%d\n", url.length);
        writef("%s\n", url);
        //writef("%s\n", cefUrl.str);
        writef("%s\n", cefUrl.str[0..url.length]);
        
        /*
        version(CEF_STRING_TYPE_UTF8) {
            int cef_string_utf8_set(const(char)* src, size_t src_len,
                                cef_string_utf8_t* output, int copy);
        } else version(CEF_STRING_TYPE_UTF16) {
            int cef_string_utf16_set(const(char16)* src, size_t src_len,
                                cef_string_utf16_t* output, int copy);
        } else version(CEF_STRING_TYPE_WIDE) {
            int cef_string_wide_set(const(wchar_t)* src, size_t src_len,
                                cef_string_wide_t* output, int copy);
        }*/






        //cef_string_utf8_to_utf16(url, strlen(url), &cefUrl);
        
        // Browser settings.
        // It is mandatory to set the "size" member.
        cef_browser_settings_t browserSettings = {};
        browserSettings.size = cef_browser_settings_t.sizeof;
        
        // Client handler and its callbacks.
        // cef_client_t structure must be filled. It must implement
        // reference counting. You cannot pass a structure 
        // initialized with zeroes.
        cef_client_t client = {};
        
        ///
        //BEGIN initialize_client_handler(&client);
        ///
        printf("initialize_client_handler\n");
        client.base.size = cef_client_t.sizeof;
        

        ///
        //BEGIN initialize_cef_base((cef_base_t*)client);
        ///
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
        /*
        client.base.add_ref = add_ref;
        client.base.release = release;
        client.base.get_refct = get_refct;
        */
        ///
        //END initialize_cef_base((cef_base_t*)client);
        ///

        // callbacks
        /*
        client.get_context_menu_handler = get_context_menu_handler;
        client.get_dialog_handler = get_dialog_handler;
        client.get_display_handler = get_display_handler;
        client.get_download_handler = get_download_handler;
        client.get_drag_handler = get_drag_handler;
        client.get_focus_handler = get_focus_handler;
        client.get_geolocation_handler = get_geolocation_handler;
        client.get_jsdialog_handler = get_jsdialog_handler;
        client.get_keyboard_handler = get_keyboard_handler;
        client.get_life_span_handler = get_life_span_handler;
        client.get_load_handler = get_load_handler;
        client.get_render_handler = get_render_handler;
        client.get_request_handler = get_request_handler;
        client.on_process_message_received = on_process_message_received;
        */
        ///
        //END initialize_client_handler(&client);
        ///



        // Create browser.
        printf("cef_browser_host_create_browser\n");
        cef_browser_host_create_browser(&windowInfo, &client, &cefUrl,
                &browserSettings, NULL);

        // Message loop.
        //printf("cef_run_message_loop\n");
        //cef_run_message_loop();

        //cef_do_message_loop_work(); 

        cef_quit_message_loop();

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
