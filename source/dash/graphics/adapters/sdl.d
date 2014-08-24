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
        }

        if( sdl.wasQuitRequested )
            DGame.instance.currentState = EngineState.Quit;
    }
}
