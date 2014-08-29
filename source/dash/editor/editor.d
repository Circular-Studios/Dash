module dash.editor.editor;
import dash.core.dgame;
import dash.editor.websockets;

import vibe.data.json;
import std.uuid;

/**
 * The editor manager class. Handles all interactions with editors.
 *
 * May be overridden to override default event implementations.
 */
class Editor
{
public:
    final void initialize( DGame instance )
    {
        game = instance;

        server.start( this );
        registerDefaultEvents();
        onInitialize();
    }

    final void update()
    {
        server.update();
    }

    final void shutdown()
    {
        server.stop();
    }

    final UUID registerEventHandler( string key, void delegate( Json ) event )
    {
        // TODO
        return randomUUID();
    }

    final UUID registerEventHandler( DataType )( string key, void delegate( DataType ) event )
    {
        return registerEventHandler( key, ( json )
        {
            deserializeJson!DataType( json );
        } );
    }

    final void processEvents()
    {
        // TODO
    }

package:
    final void queueEvent( string key, Json data )
    {
        // TODO
    }

protected:
    DGame game;
    WebSocketServer server;

    /// To be overridden
    void onInitialize() { }
    /// ditto
    void onStartPlay() { }
    /// ditto
    void onPausePlay() { }
    /// ditto
    void onStopPlay() { }

private:
    final void registerDefaultEvents()
    {
        registerEventHandler( "dgame:refresh", ( json ) { game.currentState = EngineState.Refresh; } );
    }
}
