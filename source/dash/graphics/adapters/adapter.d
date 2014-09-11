/**
* Contains all core code for the Graphics adapters, which is similar across all platforms
*/
module dash.graphics.adapters.adapter;
import dash.core.properties, dash.components.userinterface, dash.utility.config;

import gfm.math.vector: vec2i;
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
    bool _fullscreen, _backfaceCulling, _vsync;

protected:
    // Do not add properties for:
    UserInterface[] uis;

public:
    /// Pixel width of the rendering area
    mixin( Property!_width );
    /// Pixel width of the actual window
    mixin( Property!_screenWidth );
    /// Pixel height of the rendering area
    mixin( Property!_height );
    /// Pixel height of the actual window
    mixin( Property!_screenHeight );
    /// If the screen properties match the rendering dimensions
    mixin( Property!_fullscreen );
    /// Hiding backsides of triangles
    mixin( Property!_backfaceCulling );
    /// Vertical Syncing
    mixin( Property!_vsync );
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
    abstract float getDepthAtScreenPoint( vec2i point );

    /**
     * Read from the depth buffer at the given point.
     */
    abstract uint getObjectIDAtScreenPoint( vec2i point );

    /// TODO: Remove in favor of pipelines
    abstract void initializeDeferredRendering();

    /*
     * Adds a UI to be drawn over the objects in the scene
     * UIs will be drawn ( and overlap ) in the order they are added
     */
    final void addUI( UserInterface ui )
    {
        uis ~= ui;
    }

protected:
    /**
     * Loads rendering properties from Config
     */
    final void loadProperties()
    {
        fullscreen = config.find!bool( "Display.Fullscreen" );
        if( fullscreen )
        {
            width = screenWidth;
            height = screenHeight;
        }
        else
        {
            width = config.find!uint( "Display.Width" );
            height = config.find!uint( "Display.Height" );
        }

        backfaceCulling = config.find!bool( "Graphics.BackfaceCulling" );
        vsync = config.find!bool( "Graphics.VSync" );
    }
}
