
module dash.graphics.pipelines.pass;
import dash.graphics.pipelines.pipeline;
import dash.core.gameobject;

import std.array;

struct Pass
{
private:

    /// PrePassDelegates for each pipeline's pre-pass handler this pass.
    PrePassDelegate[Pipeline] prePassHandlers;
    /// PassDelegates for each pipeline's pass handler this pass.
    PassDelegate[Pipeline] passHandlers;
    /// PostPassDelegates for each pipeline's post-pass handler this pass.
    PostPassDelegate[Pipeline] postPassHandlers;
    /// Objects for each pipeline that will use this pass.
    Appender!( GameObject[] )[Pipeline] renderList;

public:

    /// Delegate for a pipeline pre-pass function.
    alias PrePassDelegate = void delegate();
    /// Delegate for a pipeline render pass function.
    alias PassDelegate = void delegate(GameObject);
    /// Delegate for a pipeline post-pass function.
    alias PostPassDelegate = void delegate();

    /**
    * Adds a pipeline's pre-pass, pass, and post-pass handler function to this pass.
    */
    void addToPass(Pipeline pipeline, PrePassDelegate prePassHandler,
                   PassDelegate passHandler, PostPassDelegate postPassHandler)
    {
        // Adds the new UUID to the pre-pass handlers with the supplied handler function.
        if (prePassHandler)
            prePassHandlers[pipeline] = prePassHandler;
        else
            prePassHandlers[pipeline] = (){ };

        // Adds the new UUID to the pass handlers with the supplied handler function.
        if (passHandler)
            passHandlers[pipeline] = passHandler;
        else
            passHandlers[pipeline] = (_){ };

        // Adds the new UUID to the post-pass handlers with the supplied handler function.
        if (postPassHandler)
            postPassHandlers[pipeline] = postPassHandler;
        else
            postPassHandlers[pipeline] = (){ };
    }

    /**
    * Removes a pipeline from this pass.
    */
    void removeFromPass(Pipeline pipeline)
    {
        // Remove everything for the specific pipeline ID from this pass
        prePassHandlers.remove(pipeline);
        passHandlers.remove(pipeline);
        postPassHandlers.remove(pipeline);
        renderList.remove(pipeline);
    }

    /**
    * Appends a gameObject to a pipeline's renderlist for this pass.
    */
    void appendToPass(Pipeline pipeline, GameObject gameObject)
    {
        renderList[pipeline].put( gameObject );
    } 

    /**
     * Renders this pass for all pipelined gameObjects.
     */
    void flush()
    {

        // Complete this pass for each pipeline
        foreach_reverse(pipeline; passHandlers.keys)
        {
            // Only do stuff for this pipeline if it has stuff in its render list
            if (pipeline in renderList)
            {
                // Invoke the pre-pass handler for this pipeline
                prePassHandlers[pipeline]();

                // Invoke the pass handler on each GameObject in the render list for this pipeline
                foreach(gameObject; renderList[pipeline].data)
                {
                    passHandlers[pipeline](gameObject);
                }

                // Invoke the post-pass handler for this pipeline
                postPassHandlers[pipeline]();

                // Clear this pipeline's render list for this pass
                renderList.remove(pipeline);
            }
        }

    }
}
