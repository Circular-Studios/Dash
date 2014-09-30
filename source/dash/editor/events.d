module dash.editor.events;
import dash.editor.editor, dash.editor.websockets;
import dash.core, dash.components.component;

import vibe.data.json;
import std.typecons;

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
/// Basic ok response.
enum ok = EventResponse( Status.ok, "success" );

package:
void registerGameEvents( Editor ed, DGame game )
{
    // Triggers an engine refresh
    ed.registerEventHandler!( Json, EventResponse )( "dgame:refresh", ( Json json ) {
        game.currentState = EngineState.Refresh;
        return ok;
    } );
}

void registerObjectEvents( Editor ed, DGame game )
{
    static struct RefreshRequest
    {
        string objectName;
        GameObject.Description description;
    }
    ed.registerEventHandler!( RefreshRequest, EventResponse )( "object:refresh", ( req ) {
        game.activeScene[ req.objectName ].refresh( req.description );
        return ok;
    } );

    static struct ComponentRefreshRequest
    {
        string objectName;
        string componentName;
        Component.Description description;
    }
    ed.registerEventHandler!ComponentRefreshRequest( "object:component:refresh", ( req ) {

    } );
}
