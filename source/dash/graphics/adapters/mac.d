/**
* TODO
*/
module dash.graphics.adapters.mac;

version( OSX ):

import dash.core.gameobject;
import dash.graphics.graphics;
import dash.graphics.adapters.adapter;

public import derelict.opengl3.cgl;
import derelict.opengl3.gl3;

public alias CGLContextObj GLRenderContext;
public alias uint GLDeviceContext;

/**
* TODO
*/
final class Mac : Adapter
{
public:
    static @property Mac get() { return cast(Mac)Graphics.adapter; }

    override void initialize() { }
    override void shutdown() { }
    override void resize() { }
    override void refresh() { }
    override void swapBuffers() { }

    override void openWindow() { }
    override void closeWindow() { }

    override void messageLoop() { }
}
