/**
* Contains all core code for the Graphics adapters, which is similar across all platforms
*/
module dash.graphics.adapters.adapter;
import dash.core.properties, dash.components.userinterface, dash.utility.config, dash.utility.math;

import std.typecons: BlackHole;

alias NullAdapter = BlackHole!Adapter;

/**
 * Base class for core rendering logic
 */
abstract class Adapter
{
private:
    uint _width, _screenWidth;
    uint _height, _screenHeight;
    bool _backfaceCulling, _vsync;
    WindowType _windowType;

public:
    /// Pixel width of the rendering area
    mixin( Property!_width );
    /// Pixel width of the actual window
    mixin( Property!_screenWidth );
    /// Pixel height of the rendering area
    mixin( Property!_height );
    /// Pixel height of the actual window
    mixin( Property!_screenHeight );
    /// Hiding backsides of triangles
    mixin( Property!_backfaceCulling );
    /// Vertical Syncing
    mixin( Property!_vsync );
    /// The type for our main window
    /// (Fullscreen, FullscreenDesktop, or Windowed)
    mixin( Property!_windowType );

    /**
     * Initializes the Adapter, called in loading
     */
    abstract void initialize();
    /**
     * Shuts down the Adapter
     */
    abstract void shutdown();
    /**
     * Resizes the window and updates FBOs
     */
    abstract void resize();
    /**
     * Reloads the Adapter without closing
     */
    abstract void refresh();
    /**
     * Swaps the back buffer to the screen
     */
    abstract void swapBuffers();

    /**
     * Opens the window
     */
    abstract void openWindow();
    /**
     * Closes the window
     */
    abstract void closeWindow();

    /**
     * TODO
     */
    abstract void messageLoop();

    /**
     * Currently the entire rendering pass for the active Scene. TODO: Refactor the name
     */
    abstract void endDraw();

    /**
     * Read from the depth buffer at the given point.
     */
    abstract float getDepthAtScreenPoint( vec2ui point );

    /**
     * Read from the depth buffer at the given point.
     */
    abstract uint getObjectIDAtScreenPoint( vec2ui point );

    /// TODO: Remove in favor of pipelines
    abstract void initializeDeferredRendering();

protected:
    /**
     * Loads rendering properties from Config
     */
    final void loadProperties()
    {
        windowType = config.display.windowMode;
        if( windowType == WindowType.Fullscreen)
        {
            width = screenWidth;
            height = screenHeight;
        }
        else
        {
            width = config.display.width;
            height = config.display.height;
        }

        backfaceCulling = config.graphics.backfaceCulling;
        vsync = config.graphics.vsync;
    }
}
