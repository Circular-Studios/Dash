
module dash.graphics.pipelines.pipeline;
import dash.core.gameobject;

import std.array;

abstract class Pipeline
{
private:
    /// Array of Appenders of delgates for each render pass. Allows synchronization of passes.
    static Appender!( void delegate()[] )[] passes;

protected:
    /// Delegate for a render pass function
    alias PassDelegate = void delegate(GameObject);

    /**
     * Adds a delegated function to a specific render pass
     */
    static void appendToPass(int index, PassDelegate passDelegate, GameObject obj)
    {
        // Make sure the selected pass has been allocated
        if (index > passes.length)
            passes.length = index + 1;

        // Append the new delegate to the selected pass
        passes[index].put( () => passDelegate( obj ) );
    }

public:
    /**
    * Initializes the Pipeline, called on loading
    */
    abstract void initialize();
    /**
     * Shuts down the Pipeline
     */
    abstract void shutdown();
    /**
     * Reloads the Pipeline without closing
     */
    abstract void refresh();
    /**
     * Adds a GameObject to the pipeline
     */
    abstract void render(GameObject gameObject);

    /**
     * Renders all pipelined gameObjects
     */
    static void flush()
    {
        // TODO: Call all functions in passes and clear it. Also ALL OTHER RENDERING STUFF!
        foreach(pass; passes)
        {
            // Render each object in each pass
            foreach(del; pass.data)
            {
                del();
            }

            // Clear the pass after rendering it
            pass.clear();
        }
    }
}
