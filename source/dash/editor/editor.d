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
    alias EventHandler( DataType ) = void delegate( DataType );
    alias EventResponseHandler( DataType, ResponseType ) = ResponseType delegate( DataType );

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
    final void send( DataType )( string key, DataType value )
    {
        EventMessage msg;
        msg.key = key;
        msg.value = value.serializeToJson();

        server.send( msg );
    }
    static assert(is(typeof( send( "key", "data" ) )));

    /**
     * Sends a message to all attached editors.
     *
     * Params:
     *  key =           The key of the event.
     *  value =         The data along side it.
     *  cb =            The callback to call when a response is received.
     */
    final void send( ResponseType = EventResponse, DataType )( string key, DataType value, EventHandler!ResponseType cb )
    {
        UUID cbId = randomUUID();
        registerCallbackHandler( cbId, msg => cb( msg.value.deserializeJson!ResponseType ) );

        EventMessage msg;
        msg.key = key;
        msg.value = value.serializeToJson();
        msg.callbackId = cbId.toString();

        server.send( msg );
    }
    static assert(is(typeof( send!( string )( "key", "data", ( string response ) { } ) )));

    /**
     * Registers an event callback, for when an event with the given key is received.
     *
     * Params:
     *  key =           The key of the event.
     *  event =         The handler to call.
     *
     * Returns: The ID of the event, so it can be unregistered later.
     */
    final UUID registerEventHandler( DataType )( string key, EventHandler!DataType event )
    {
        return registerInternalMessageHandler( key, msg => event( msg.value.deserializeJson!DataType ) );
    }
    static assert(is(typeof( registerEventHandler!string( "key", ( string resp ) { } ) )));

    /**
     * Registers an event callback, for when an event with the given key is received.
     *
     * Params:
     *  key =           The key of the event.
     *  event =         The handler to call.
     *
     * Returns: The ID of the event, so it can be unregistered later.
     */
    final UUID registerEventHandler( DataType, ResponseType )( string key, EventResponseHandler!( DataType, ResponseType ) event )
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
    static assert(is(typeof( registerEventHandler!( string, string )( "key", data => data ) )));

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
    enum CallbackMessageKey = "__callback__";

    alias InternalEventHandler = void delegate( EventMessage );
    alias EventHandlerTuple = Tuple!(UUID, "id", InternalEventHandler, "handler");

    /// Register an event from the front end.
    final void queueEvent( EventMessage msg )
    {
        pendingEvents ~= msg;
    }

    /// Register a message internally, after generating a handler for it.
    final UUID registerInternalMessageHandler( string key, InternalEventHandler handler )
    {
        auto id = randomUUID();
        eventHandlers[ key ] ~= EventHandlerTuple( id, handler );
        return id;
    }

    /// If a send call requests a callback, register it.
    final void registerCallbackHandler( UUID id, InternalEventHandler handler )
    {
        callbacks[ id ] = handler;
    }

    /// Register built-in event handlers.
    final void registerDefaultEvents()
    {
        registerInternalMessageHandler( CallbackMessageKey, &handleCallback );

        // Test handler, responds with request
        registerEventHandler!( Json, Json )( "loopback", json => json );

        registerGameEvents( this, game );
        registerObjectEvents( this, game );
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

private:
    EventMessage[] pendingEvents;
    EventHandlerTuple[][string] eventHandlers;
    InternalEventHandler[UUID] callbacks;
}
