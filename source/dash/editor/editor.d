module dash.editor.editor;
import dash.core.dgame;
import dash.editor.websockets, dash.editor.events;
import dash.utility.output;

import vibe.data.json;
import vibe.http.status: HTTPStatus;
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
    alias JsonEventResponseHandler = Json delegate( Json );
    alias TypedEventHandler( DataType ) = void delegate( DataType );
    alias TypedEventResponseHandler( ResponseType, DataType ) = ResponseType delegate( DataType );

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

    /**
     * Sends a message to all attached editors.
     *
     * Params:
     *  key =           The key of the event.
     *  value =         The data along side it.
     *  cb =            The callback to call when a response is received.
     */
    final void send( string key, Json value, JsonEventHandler cb )
    {
        UUID cbId = randomUUID();
        registerCallbackHandler( cbId, msg => cb( msg.value ) );

        EventMessage msg;
        msg.key = key;
        msg.value = value;
        msg.callbackId = cbId.toString();

        server.send( msg );
    }

    /**
     * Sends a message to all attached editors.
     *
     * Params:
     *  key =           The key of the event.
     *  value =         The data along side it.
     */
    final void send( DataType )( string key, DataType value )
    {
        send( key, value.serializeToJson() );
    }
    static assert(is(typeof( send!( string )( "key", "data" ) )));

    /**
     * Sends a message to all attached editors.
     *
     * Params:
     *  key =           The key of the event.
     *  value =         The data along side it.
     *  cb =            The callback to call when a response is received.
     */
    final void send( ResponseType, DataType )( string key, DataType value, TypedEventHandler!ResponseType cb )
    {
        send( key, value.serializeToJson(), ( Json json ) { cb( json.deserializeJson!ResponseType ); } );
    }
    static assert(is(typeof( send!( string, string )( "key", "data", ( response ) { } ) )));

    /**
     * Registers an event callback, for when an event with the given key is received.
     *
     * Params:
     *  key =           The key of the event.
     *  event =         The handler to call.
     *
     * Returns: The ID of the event, so it can be unregistered later.
     */
    final UUID registerEventHandler( string key, JsonEventHandler event )
    {
        void handler( EventMessage msg )
        {
            event( msg.value );
        }

        return registerInternalMessageHandler( key, &handler );
    }

    /**
     * Registers an event callback, for when an event with the given key is received.
     *
     * Params:
     *  key =           The key of the event.
     *  event =         The handler to call.
     *
     * Returns: The ID of the event, so it can be unregistered later.
     */
    final UUID registerEventHandler( string key, JsonEventResponseHandler event )
    {
        void handler( EventMessage msg )
        {
            Json res = event( msg.value );

            EventMessage newMsg;
            newMsg.key = CallbackMessageKey;
            newMsg.value = res;
            newMsg.callbackId = msg.callbackId;

            server.send( newMsg );
        }

        return registerInternalMessageHandler( key, &handler );
    }

    /**
     * Registers an event callback, for when an event with the given key is received.
     *
     * Params:
     *  key =           The key of the event.
     *  event =         The handler to call.
     *
     * Returns: The ID of the event, so it can be unregistered later.
     */
    final UUID registerEventHandler( DataType )( string key, TypedEventHandler!DataType event )
    {
        void handler( EventMessage msg )
        {
            event( msg.value.deserializeJson!DataType() );
        }

        return registerInternalMessageHandler( key, &handler );
    }
    static assert(is(typeof( registerEventHandler!( string )( "key", ( data ) { } ) )));

    /**
     * Registers an event callback, for when an event with the given key is received.
     *
     * Params:
     *  key =           The key of the event.
     *  event =         The handler to call.
     *
     * Returns: The ID of the event, so it can be unregistered later.
     */
    final UUID registerEventHandler( ResponseType, DataType )( string key, TypedEventResponseHandler!( ResponseType, DataType ) event )
    {
        void handler( EventMessage msg )
        {
            ResponseType res = event( msg.value.deserializeJson!DataType );

            EventMessage newMsg;
            newMsg.key = CallbackMessageKey;
            newMsg.value = res.serializeToJsonString();
            newMsg.callbackId = msg.callbackId;

            server.send( newMsg );
        }

        return registerInternalMessageHandler( key, &handler );
    }
    static assert(is(typeof( registerEventHandler!( string, string )( "key", ( data ) { return data; } ) )));

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

    /**
     * Processes all pending events.
     *
     * Called by update.
     */
    final void processEvents()
    {
        // Clear the events
        scope(exit) pendingEvents.length = 0;

        foreach( event; pendingEvents )
        {
            // Dispatch to handlers.
            if( auto handlerTupArray = event.key in eventHandlers )
            {
                foreach( handlerTup; *handlerTupArray )
                {
                    handlerTup.handler( event );
                }
            }
            else
            {
                logWarning( "Invalid editor event received with key ", event.key );
            }
        }
    }

package:
    /// The message key for callbacks
    package enum CallbackMessageKey = "__callback__";

    alias InternalEventHandler = void delegate( EventMessage );
    alias EventHandlerTuple = Tuple!(UUID, "id", InternalEventHandler, "handler");

    EventMessage[] pendingEvents;
    EventHandlerTuple[][string] eventHandlers;
    InternalEventHandler[UUID] callbacks;

    final void queueEvent( EventMessage msg )
    {
        pendingEvents ~= msg;
    }

    /// Register a 
    final UUID registerInternalMessageHandler( string key, InternalEventHandler handler )
    {
        auto id = randomUUID();
        eventHandlers[ key ] ~= EventHandlerTuple( id, handler );
        return id;
    }

    final void registerCallbackHandler( UUID id, InternalEventHandler handler )
    {
        callbacks[ id ] = handler;
    }

    final void registerDefaultEvents()
    {
        registerInternalMessageHandler( CallbackMessageKey, &handleCallback );

        // Test handler, responds with request
        registerEventHandler( "loopback", json => json );
        // Triggers an engine refresh
        registerEventHandler!( int, Json )( "dgame:refresh", ( json ) {
            game.currentState = EngineState.Refresh;
            return HTTPStatus.ok;
        } );
    }

    /// Handles callback messages
    final void handleCallback( EventMessage msg )
    {
        // If it's a callback, dispatch it as such.
        UUID id = msg.callbackId.parseUUID();
        if( auto cb = id in callbacks )
        {
            (*cb)( msg );
            callbacks.remove( id );
        }
        else
        {
            logFatal( "Callback reference lost: ", msg.callbackId );
        }
    }
}
