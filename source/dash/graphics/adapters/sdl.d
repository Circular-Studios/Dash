module dash.graphics.adapters.sdl;
import dash.core.dgame;
//import dash.graphics.graphics;
import dash.graphics;
import dash.graphics.adapters.adapter;
import dash.utility;

import derelict.opengl3.gl3, gfm.sdl2;
import std.string, std.file;

class Sdl : OpenGL
{
private:
    SDL2Window window;
    SDL2GLContext glContext;

public:
    SDL2 sdl;

    static @property Sdl get() { return cast(Sdl)Graphics.adapter; }

    override void initialize()
    {
        import dash.utility.output: DashLogger;

        // Initialize OpenGL
        DerelictGL3.load();
        // Initialize SDL
        sdl = new SDL2( DashLogger.multiLogger );
        sdl.subSystemInit( SDL_INIT_VIDEO );
        sdl.subSystemInit( SDL_INIT_EVENTS );
        sdl.subSystemInit( SDL_INIT_JOYSTICK );
        sdl.subSystemInit( SDL_INIT_GAMECONTROLLER );

        // Get screen size.
        screenWidth = sdl.firstDisplaySize().x;
        screenHeight = sdl.firstDisplaySize().y;

        // Load properties from config.
        loadProperties();

        window = new SDL2Window( sdl,
            ( screenWidth - width ) / 2, ( screenHeight - height ) / 2,
            width, height,
            SDL_WINDOW_OPENGL );

        window.setTitle( DGame.instance.title );

        if(config.graphics.usingGl33)
        {
            SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
            SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
        }
        else
        {
            SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 4);
            SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 0);
        }
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);

        string iconPath = Resources.Textures ~ "/icon.bmp";

        if( exists( iconPath ) )
        {
            SDLImage imageLib = new SDLImage( sdl, 0 );
            window.setIcon( imageLib.load( iconPath ) );
        }
        else
        {
            trace("Could not find icon.bmp in Textures folder!");
        }

        glContext = new SDL2GLContext( window );
        glContext.makeCurrent();

        DerelictGL3.reload();

        if(config.graphics.vsync)
        {
            SDL_GL_SetSwapInterval(1);
            trace("vsync enabled!");
        }
        else
        {
            SDL_GL_SetSwapInterval(0);
            trace("vsync disabled!");
        }
        resize();
    }

    override void shutdown()
    {
        glContext.close();
        window.close();
        sdl.close();
    }

    override void resize()
    {
        loadProperties();

        bool bordered = false;
        
        switch( windowType )
        {
            case WindowType.Fullscreen:
                trace("Setting main window to Fullscreen mode!");
                window.setFullscreenSetting( SDL_WINDOW_FULLSCREEN );
                break;
            case WindowType.FullscreenWindowed:
                trace("Setting main window to Fullscreen Windowed mode!");
                bordered = false;
                width = screenWidth;
                height = screenHeight;
                goto default;
            case WindowType.Windowed:
                trace("Setting main window to Windowed mode!");
                bordered = true;
                goto default;
            case WindowType.BorderlessWindow:
                trace("Setting main window to Borderless Windowed mode!");
                bordered = false;
                goto default;
            default: 
                window.setFullscreenSetting( 0 );
                window.setSize( width, height );
                window.setBordered( bordered );
                break;
        }

        resizeDefferedRenderBuffer();
        glViewport( 0, 0, width, height );
    }

    override void refresh()
    {
        resize();
        swapBuffers();
    }

    override void swapBuffers()
    {
        auto zone = DashProfiler.startZone( "Swap Buffers" );
        window.swapBuffers();
    }

    //Don't know if we need this...
    override void openWindow()
    {

    }

    override void closeWindow()
    {
        window.close();

    }

    override void messageLoop()
    {
        SDL_Event event;
        while( sdl.pollEvent( &event ) )
        {
            // Handle the messages and stuffs.
            switch( event.type )
            {
                // Handle mouse interactions.
                case SDL_MOUSEBUTTONDOWN:
                case SDL_MOUSEBUTTONUP:
                {
                    Mouse.Buttons button;
                    final switch( event.button.button )
                    {
                        case SDL_BUTTON_LEFT:   button = Mouse.Buttons.Left;    break;
                        case SDL_BUTTON_MIDDLE: button = Mouse.Buttons.Middle;  break;
                        case SDL_BUTTON_RIGHT:  button = Mouse.Buttons.Right;   break;
                        case SDL_BUTTON_X1:     break;
                        case SDL_BUTTON_X2:     break;
                    }

                    Mouse.setButtonState( button, event.button.state == SDL_PRESSED );
                    break;
                }

                //On keypress
                case SDL_KEYDOWN:
                    Keyboard.setButtonState( cast(Keyboard.Buttons)event.key.keysym.sym, true );
                    break;

                //On keyrelease
                case SDL_KEYUP:
                    Keyboard.setButtonState( cast(Keyboard.Buttons)event.key.keysym.sym, false );
                    break;

                // Handle quitting.
                case SDL_QUIT:
                    DGame.instance.currentState = EngineState.Quit;
                    break;

                case SDL_MOUSEWHEEL:
                    Mouse.setAxisState( Mouse.Axes.ScrollWheel, Mouse.getAxisState( Mouse.Axes.ScrollWheel ) + event.wheel.y );
                    break;

                case SDL_APP_TERMINATING:
                    shutdown();
                    break;

                case SDL_MOUSEMOTION:
                    Mouse.setAxisState( Mouse.Axes.XPos, event.motion.x );
                    Mouse.setAxisState( Mouse.Axes.YPos, Graphics.height - event.motion.y );
                    break;

                case SDL_APP_LOWMEMORY:
                case SDL_APP_WILLENTERBACKGROUND:
                case SDL_APP_DIDENTERBACKGROUND:
                case SDL_APP_WILLENTERFOREGROUND:
                case SDL_APP_DIDENTERFOREGROUND:
                case SDL_WINDOWEVENT:
                case SDL_SYSWMEVENT:
                case SDL_TEXTEDITING:
                case SDL_TEXTINPUT:
                case SDL_JOYAXISMOTION:
                case SDL_JOYBALLMOTION:
                case SDL_JOYHATMOTION:
                case SDL_JOYBUTTONDOWN:
                case SDL_JOYBUTTONUP:
                case SDL_JOYDEVICEADDED:
                case SDL_JOYDEVICEREMOVED:
                case SDL_CONTROLLERAXISMOTION:
                case SDL_CONTROLLERBUTTONDOWN:
                case SDL_CONTROLLERBUTTONUP:
                case SDL_CONTROLLERDEVICEADDED:
                case SDL_CONTROLLERDEVICEREMOVED:
                case SDL_CONTROLLERDEVICEREMAPPED:
                case SDL_FINGERDOWN:
                case SDL_FINGERUP:
                case SDL_FINGERMOTION:
                case SDL_DOLLARGESTURE:
                case SDL_DOLLARRECORD:
                case SDL_MULTIGESTURE:
                case SDL_CLIPBOARDUPDATE:
                case SDL_DROPFILE:
                case SDL_RENDER_TARGETS_RESET:
                case SDL_USEREVENT:
                // Unknown event type
                default:
                    break;
            }
        }
    }
}
