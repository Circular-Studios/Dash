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
        version( Windows )
        {
            adapter = new Win32GL;
        }
        else version( linux )
        {
            adapter = new Linux;
        }
        else
        {
            adapter = new NullAdapter;
        }

        adapter.initialize();
        adapter.initializeDeferredRendering();  // TODO: Eventually moved to initialize with pipelines.
        Shaders.initialize();   // TODO: Also eventually moved to initialize with pipelines as shaders are pipeline specific.
    }

    /**
     * Shutdown the adapter and shaders.
     */
    final void shutdown()
    {
        Shaders.shutdown(); // TODO: adapter.shutdown should do this with pipelines.
        adapter.shutdown();
    }

private:
    this() { }
}
