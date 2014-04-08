module graphics.adapters.mac;

version( OSX ):

import core.gameobject;
import graphics.graphics;
import graphics.adapters.adapter;

import derelict.opengl3.gl3, derelict.opengl3.cgl;

alias CGLContextObj GLRenderContext;
alias uint GLDeviceContext;

final class Mac : Adapter
{
public:
    static @property Mac get() { return cast(Mac)Graphics.adapter; }

    override void initialize()
    {

    }
    
    override void shutdown()
    {

    }
    
    override void resize()
    {

    }
    
    override void reload()
    {

    }
    
    override void beginDraw()
    {

    }

    override void drawObject( GameObject obj )
    {

    }
    
    override void endDraw()
    {

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
