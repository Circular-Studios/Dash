module dash.editor.events;
import dash.editor.editor, dash.editor.websockets;
import dash.core, dash.components.component;

import vibe.data.json;
import std.typecons, std.functional;

public:
/// Easy to handle response struct.
struct EventResponse
{
    /// Status of a request
    enum Status
    {
        ok = 0,
        warning = 1,
        error = 2,
    }

    Status status;
    Json data;
}
/// Shortcut to generate response.
EventResponse res( DataType = Json )( EventResponse.Status s, DataType d = DataType.init )
{
    return EventResponse( s, d.serializeToJson() );
}

struct response
{
    @disable this();

    /// Basic ok response.
    alias ok = partial!( res, EventResponse.Status.ok );
    /// Error response
    alias error = partial!( res, EventResponse.Status.error );
}

package:
void registerGameEvents( Editor ed, DGame game )
{
    // Triggers an engine refresh
    ed.registerEventHandler!( Json, EventResponse )( "dgame:refresh", ( _ ) {
        game.currentState = EngineState.Refresh;
        return response.ok;
    } );

    ed.registerEventHandler!( Json, EventResponse )( "dgame:scene:get_objects", ( _ ) {
        return response.ok( game.activeScene.objects );
    } );
}

void registerObjectEvents( Editor ed, DGame game )
{
    // Refresh an object
    static struct RefreshRequest
    {
        string objectName;
        GameObject.Description description;
    }
    ed.registerEventHandler!( RefreshRequest, EventResponse )( "object:refresh", ( req ) {
        if( auto obj = game.activeScene[ req.objectName ] )
        {
            obj.refresh( req.description );
            return response.ok;
        }
        else
        {
            return response.error( "Object " ~ req.objectName ~ " not found." );
        }
    } );

    // Refresh a component
    static struct ComponentRefreshRequest
    {
        string objectName;
        string componentName;
        Component.Description description;
    }
    ed.registerEventHandler!( ComponentRefreshRequest, EventResponse )( "object:component:refresh", ( req ) {
        if( auto obj = game.activeScene[ req.objectName ] )
        {
            obj.refreshComponent( req.componentName, req.description );
            return response.ok;
        }
        else
        {
            return response.error( "Object " ~ req.objectName ~ " not found." );
        }
    } );
}
