module dash.graphics.adapters.sdl;
import dash.core.dgame;
import dash.graphics.graphics;
import dash.graphics.adapters.adapter;
import dash.utility;

import derelict.opengl3.gl3;
import derelict.sdl2.sdl;
import std.string;

class Sdl : Adapter
{
private:
    SDL_Window* window;
    SDL_GLContext context;

public:
    static @property Sdl get() { return cast(Sdl)Graphics.adapter; }

    override void initialize()
    {
        DerelictGL3.load();
        DerelictSDL2.load();
        loadProperties();

        SDL_Init( SDL_INIT_VIDEO );

        window = SDL_CreateWindow(
            DGame.instance.title.toStringz(),
            SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
            width, height,
            SDL_WINDOW_OPENGL
        );

        context = SDL_GL_CreateContext( window );

        DerelictGL3.reload();
    }

    override void shutdown()
    {
        SDL_GL_DeleteContext( context );
        SDL_DestroyWindow( window );
        SDL_Quit();
    }

    override void resize()
    {
        loadProperties();

        SDL_SetWindowSize( window, width, height );
    }

    override void refresh()
    {
        resize();
    }

    override void swapBuffers()
    {
        SDL_GL_SwapWindow( window );
    }

    override void openWindow()
    {

    }

    override void closeWindow()
    {

    }

    override void messageLoop()
    {

    }
}
