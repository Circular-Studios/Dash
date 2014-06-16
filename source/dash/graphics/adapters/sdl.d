module dash.graphics.adapters.sdl;
import dash.core.dgame;
import dash.graphics.graphics;
import dash.graphics.adapters.adapter;
import dash.utility;

import derelict.sdl2.sdl;
import std.string;

class Sdl : Adapter
{
private:
    SDL_Window* window;

public:
    static @property Sdl get() { return cast(Sdl)Graphics.adapter; }

    override void initialize()
    {
        logInfo("Initialize begin!");

        DerelictSDL2.load();
        loadProperties();

        SDL_Init( SDL_INIT_VIDEO );

        window = SDL_CreateWindow(
            DGame.instance.title.toStringz(),
            SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
            width, height,
            SDL_WINDOW_OPENGL
        );

        logInfo("Initialize done!");
    }

    override void shutdown()
    {
        SDL_DestroyWindow( window );
        SDL_Quit();
    }

    override void resize()
    {
        loadProperties();

        if( fullscreen )
        {

        }
        else
        {
            SDL_SetWindowSize( window, width, height );
        }
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
