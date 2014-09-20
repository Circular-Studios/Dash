
module dash.graphics.pipelines.pass;
import dash.core.gameobject;

import std.array;
import std.uuid;

class Pass
{
private:

    /// PrePassDelegates for each pipeline's pre-pass handler this pass.
    PrePassDelegate[UUID] prePassHandlers;
    /// PassDelegates for each pipeline's pass handler this pass.
    PassDelegate[UUID] passHandlers;
    /// Objects for each pipeline that will use this pass.
    Appender!( GameObject[] )[UUID] renderList;

public:

    alias PrePassDelegate = void delegate();

    /// Delegate for a render pass function
    alias PassDelegate = void delegate(GameObject);

    /**
    * Adds a pipeline's pre-pass and pass handler function to this pass.
    */
    void addToPass(UUID pipeID, PassDelegate passHandler, PrePassDelegate prePassHandler)
    {
        // Adds the new UUID to the pre-pass handlers with the supplied handler function.
        if (prePassHandler)
            prePassHandlers[pipeID] = prePassHandler;
        else
            prePassHandlers[pipeID] = (){ };
        // Adds the new UUID to the pass handlers with the supplied handler function.
        passHandlers[pipeID] = passHandler;
    }

    /**
    * Appends a gameObject to a pipeline's renderlist for this pass.
    */
    void appendToPass(UUID pipeID, GameObject gameObject)
    {
        renderList[pipeID].put( gameObject );
    }

    

    /**
     * Renders this pass for all pipelined gameObjects.
     */
    void flush()
    {
        // Complete this pass for each pipeline
        foreach(pipeID; passHandlers.keys)
        {
            // Invoke the prePass function for this pipeline first
            prePassHandlers[pipeID]();

            // Then invoke the pass function on each gameObject for this pipeline
            foreach(gameObject; renderList[pipeID].data)
            {
                passHandlers[pipeID](gameObject);
            }

            // Remove this pipeline from the pass
            prePassHandlers.remove(pipeID);
            passHandlers.remove(pipeID);
            renderList.remove(pipeID);
        }
    }
}
