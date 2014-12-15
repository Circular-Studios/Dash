/**
 * Container for the graphics adapter needed for the appropriate platform
 */
module dash.graphics.graphics;
import dash.graphics.adapters, dash.graphics.shaders;

/**
 * Abstract class to store the appropriate Adapter
 */
final abstract class Graphics
{
public static:
    /// The active Adapter
    Adapter adapter;
    /// Aliases adapter to Graphics
    alias adapter this;

    /**
     * Initialize the controllers.
     */
    final void initialize()
    {
        version( DashUseNativeAdapter )
        {
            version( Windows )
            {
                import dash.graphics.adapters.win32gl;
                adapter = new Win32GL;
            }
            else version( linux )
            {
                import dash.graphics.adapters.linux;
                adapter = new Linux;
            }
        }
        else
        {
            adapter = new Sdl;
        }

        adapter.initialize();
        adapter.initializeDeferredRendering();
        Shaders.initialize();
    }

    /**
     * Shutdown the adapter and shaders.
     */
    final void shutdown()
    {
        Shaders.shutdown();
        adapter.shutdown();
    }

private:
    this() { }
}
