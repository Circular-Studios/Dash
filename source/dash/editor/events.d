module dash.editor.events;
import dash.editor.editor, dash.editor.websockets;
import dash.core, dash.components.component;

import vibe.data.json;
import std.typecons, std.functional;

public:
/// Status of a request
enum Status
{
    ok,
    warning,
    error,
}
/// Easy to handle response struct.
struct EventResponse
{
    Status status;
    string message;
}
/// Shortcut to generate response.
EventResponse res( Status s, string m )
{
    return EventResponse( s, m );
}

struct response
{
    @disable this();

    /// Basic ok response.
    enum ok = EventResponse( Status.ok, "success" );
    /// Warning response
    alias warning = partial!( res, Status.warning );
    /// Error response
    alias error = partial!( res, Status.error );
}

package:
void registerGameEvents( Editor ed, DGame game )
{
    // Triggers an engine refresh
    ed.registerEventHandler!( Json, EventResponse )( "dgame:refresh", ( Json json ) {
        game.currentState = EngineState.Refresh;
        return response.ok;
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
