module dash.editor.editor;
import dash.core.dgame;
import dash.editor.websockets;
import dash.utility.output;

import vibe.data.json;
import std.uuid, std.typecons;

/**
 * The editor manager class. Handles all interactions with editors.
 *
 * May be overridden to override default event implementations.
 */
class Editor
{
public:
    // Event handlers
    alias JsonEventHandler = void delegate( Json );
    alias TypedEventHandler( Type ) = void delegate( Type );

    /**
     * Initializes the editor with a DGame instance.
     *
     * Called by DGame.
     */
    final void initialize( DGame instance )
    {
        game = instance;

        server.start( this );
        registerDefaultEvents();
        onInitialize();
    }

    /**
     * Processes pending events.
     *
     * Called by DGame.
     */
    final void update()
    {
        server.update();
        processEvents();
    }

    /**
     * Shutsdown the editor interface.
     *
     * Called by DGame.
     */
    final void shutdown()
    {
        server.stop();
    }

    /**
     * Sends a message to all attached editors.
     *
     * Params:
     *  key =           The key of the event.
     *  value =         The data along side it.
     */
    final void send( string key, Json value )
    {
        EventMessage msg;
        msg.key = key;
        msg.value = value;

        server.send( msg );
    }

    final void send( DataType )( string key, DataType value )
    {
        send( key, value.serializeToJson() );
    }

    final UUID registerEventHandler( string key, JsonEventHandler event )
    {
        auto id = randomUUID();
        eventHandlers[ key ] ~= EventHandlerTuple( id, event );
        return id;
    }

    /**
     * Registers an event callback, for when an event with the given key is received.
     *
     * Params:
     *  key =           The key of the event.
     *  event =         The handler to call.
     *
     * Returns: The ID of the event, so it can be unretistered later.
     */
    final UUID registerEventHandler( DataType )( string key, TypedEventHandler!DataType event )
    {
        return registerEventHandler( key, ( json ) {
            deserializeJson!DataType( json );
        } );
    }

    /**
     * Unregisters an event callback.
     *
     * Params:
     *  id =            The id of the handler to remove.
     */
    final void unregisterEventHandler( UUID id )
    {
        foreach( _, handlerTupArr; eventHandlers )
        {
            foreach( i, handlerTup; handlerTupArr )
            {
                if( handlerTup.id == id )
                {
                    auto end = handlerTupArr[ i+1..$ ];
                    handlerTupArr = handlerTupArr[ 0..i ] ~ end;
                }
            }
        }
    }

    final void processEvents()
    {
        // Clear the events
        scope(exit) pendingEvents.length = 0;

        foreach( event; pendingEvents )
        {
            if( auto handlerTupArray = event.key in eventHandlers )
            {
                foreach( handlerTup; *handlerTupArray )
                {
                    handlerTup.handler( event.value );
                }
            }
            else
            {
                logWarning( "Invalid editor event received with key ", event.key );
            }
        }
    }

package:
    final void queueEvent( EventMessage msg )
    {
        pendingEvents ~= msg;
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
    alias EventHandlerTuple = Tuple!(UUID, "id", JsonEventHandler, "handler");

    EventHandlerTuple[][string] eventHandlers;
    EventMessage[] pendingEvents;

    final void registerDefaultEvents()
    {
        registerEventHandler( "dgame:refresh", ( json ) { game.currentState = EngineState.Refresh; } );
        registerEventHandler( "loopback", json => send( "loopback", json ) );
    }
}
