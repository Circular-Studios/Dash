
module dash.graphics.pipelines.pipeline;
import dash.graphics.pipelines.pass;
import dash.core.gameobject;

import std.array;

abstract class Pipeline
{
private:
    /// All pipeline agnostic render passes @ render time. Allows synchronization of passes across pipelines.
    static Pass[] passes;

protected:
    /// Delegate for a pipeline pre-pass function.
    alias PrePassDelegate = Pass.PrePassDelegate;
    /// Delegate for a pipeline render pass function.
    alias PassDelegate = Pass.PassDelegate;
    /// Delegate for a pipeline post-pass function.
    alias PostPassDelegate = Pass.PostPassDelegate;

    /**
    * Adds a pipeline's pre-pass and pass handler function to a specific pass.
    */
    static void addToPass(uint index, Pipeline pipeline, PrePassDelegate prePassHandler, 
                          PassDelegate passHandler, PostPassDelegate postPassHandler)
    {
        // Make sure the selected pass exists. If not, create it.
        if (index > passes.length)
            passes.length = index + 1;

        // Add the pipeline and it's handlers to the specific pass.
        passes[index].addToPass(pipeline, prePassHandler, passHandler, postPassHandler);
    }

    /**
    * Removes a pipeline from a specific pass.
    */
    void removeFromPass(uint index, Pipeline pipeline)
    {
        passes[index].removeFromPass(pipeline);
    }

    /**
    * Appends a gameObject to a pipeline's renderlist for a specific pass.
    */
    static void appendToPass(uint index, Pipeline pipeline, GameObject gameObject)
    {
        // Make sure the selected pass exists. If not, create it.
        if (index > passes.length)
            passes.length = index + 1;

        // Append the new delegate to the selected pass.
        passes[index].appendToPass(pipeline, gameObject);
    }

public:
    /**
    * Initializes the Pipeline, called on loading.
    */
    abstract void initialize();
    /**
     * Shuts down the Pipeline.
     */
    abstract void shutdown();
    /**
     * Reloads the Pipeline without closing.
     */
    abstract void refresh();
    /**
     * Adds a GameObject to the pipeline.
     */
    abstract void render(GameObject gameObject);

    /**
     * Renders all pipelined GameObjects.
     */
    static void flush()
    {
        foreach(pass; passes)
        {
            // Flush each pass in order of their index
            pass.flush();
        }

        // Clear our passes
        passes.length = 0;
    }
}
