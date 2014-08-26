module dash.graphics.adapters.sdl;
import dash.core.dgame;
import dash.graphics.graphics;
import dash.graphics.adapters.adapter;
import dash.utility;

import derelict.opengl3.gl3, gfm.sdl2;
import std.string;

class Sdl : Adapter
{
private:
    SDL2 sdl;
    SDL2Window window;
    SDL2GLContext glContext;

public:
    static @property Sdl get() { return cast(Sdl)Graphics.adapter; }

    override void initialize()
    {
        // Initialize OpenGL
        DerelictGL3.load();
        // Initialize SDL
        sdl = new SDL2( null );

        // Get screen size.
        screenWidth = sdl.firstDisplaySize().x;
        screenHeight = sdl.firstDisplaySize().y;

        // Load properties from config.
        loadProperties();

        //SDL_Init( SDL_INIT_VIDEO );

        /*window = SDL_CreateWindow(
            DGame.instance.title.toStringz(),
            SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
            width, height,
            SDL_WINDOW_OPENGL
        );*/
        window = new SDL2Window( sdl,
            ( screenWidth - width ) / 2, ( screenHeight - height ) / 2,
            width, height,
            SDL_WINDOW_OPENGL );

        window.setTitle( DGame.instance.title );

        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 4);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 0); 
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);

        //context = SDL_GL_CreateContext( window );
        glContext = new SDL2GLContext( window );
        glContext.makeCurrent();

        DerelictGL3.reload();
    }

    override void shutdown()
    {
        /*SDL_GL_DeleteContext( context );
        SDL_DestroyWindow( window );
        SDL_Quit();*/
        glContext.close();
        window.close();
        sdl.close();
    }

    override void resize()
    {
        loadProperties();

        window.setSize( width, height );
    }

    override void refresh()
    {
        resize();
    }

    override void swapBuffers()
    {
        window.swapBuffers();
    }

    override void openWindow()
    {

    }

    override void closeWindow()
    {

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
                
                //
                case SDL_KEYDOWN:
                case SDL_KEYUP:
                {
                    break;
                }

                // Handle quitting.
                case SDL_QUIT:
                    DGame.instance.currentState = EngineState.Quit;
                    break;

                case SDL_APP_TERMINATING:
                case SDL_APP_LOWMEMORY:
                case SDL_APP_WILLENTERBACKGROUND:
                case SDL_APP_DIDENTERBACKGROUND:
                case SDL_APP_WILLENTERFOREGROUND:
                case SDL_APP_DIDENTERFOREGROUND:
                case SDL_WINDOWEVENT:
                case SDL_SYSWMEVENT:
                case SDL_TEXTEDITING:
                case SDL_TEXTINPUT:
                case SDL_MOUSEMOTION:
                case SDL_MOUSEWHEEL:
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
