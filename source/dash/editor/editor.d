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
        send( key, value, ( Json res ) { } );
    }
    static assert(is(typeof( send( "key", "data" ) )));

    /**
     * Sends a message to all attached editors.
     *
     * In most cases, you won't have to manually specify template parameters,
     * they should be inferred.
     *
     * Params:
     *  key =           The key of the event.
     *  value =         The data along side it.
     *  cb =            The callback to call when a response is received.
     *
     * Examples:
     * ---
     * // DataType inferred as string, ResponseType inferred as string.
     * editor.send( "my_key", "my_value", ( string response ) {
     *     // Handle response
     * } );
     * ---
     */
    final void send( DataType, ResponseType )( string key, DataType value, void delegate( ResponseType ) cb )
    {
        UUID cbId = randomUUID();

        void callbackHandler( EventMessage msg )
        {
            auto response = msg.value.deserializeJson!EventResponse;

            if( response.status == EventResponse.Status.ok )
                cb( response.data.deserializeJson!ResponseType );
            else
                throw response.data.deserializeJson!TransferableException().toException();
        }
        registerCallbackHandler( cbId, &callbackHandler );

        EventMessage msg;
        msg.key = key;
        msg.value = value.serializeToJson();
        msg.callbackId = cbId.toString();

        server.send( msg );
    }
    static assert(is(typeof( send( "key", "data", ( string response ) { } ) )));

    /**
     * Registers an event callback, for when an event with the given key is received.
     *
     * Params:
     *  key =           The key of the event.
     *  event =         The handler to call.
     *
     * * Examples:
     * ---
     * // DataType inferred as string, ResponseType inferred as string.
     * editor.registerEventHandler( "loopback", ( string receivedData ) {
     *     // Handle response
     *     // Return your response, or nothing if signify success without response.
     *     return receivedData;
     * } );
     *
     * Returns: The ID of the event, so it can be unregistered later.
     */
    final UUID registerEventHandler( DataType, ResponseType )( string key, ResponseType delegate( DataType ) event )
    {
        void handler( EventMessage msg )
        {
            // Automatically deserialize received data to requested type.
            DataType receivedData;
            try
            {
                receivedData = msg.value.deserializeJson!DataType;
            }
            catch( JSONException e )
            {
                errorf( "Error deserializing received message with key \"%s\" to %s: %s", key, DataType.stringof, e.msg );
                return;
            }

            // Create a message with the callback id, and the response of the event.
            EventMessage newMsg;
            newMsg.key = CallbackMessageKey;
            newMsg.callbackId = msg.callbackId;

            // Build response to send back
            EventResponse res;

            try
            {
                static if(is( ResponseType == void ))
                {
                    // Call the event handler.
                    event( receivedData );
                    res.data = Json( "success" );
                }
                else
                {
                    // Call the event handler, and capture the result.
                    ResponseType result = event( receivedData );
                    res.data = result.serializeToJson();
                }

                // If we've made it this far, it's a success
                res.status = EventResponse.Status.ok;
            }
            catch( Exception e )
            {
                // If failure, send exception.
                res.status = EventResponse.Status.error;
                res.data = TransferableException.fromException( e ).serializeToJson();
            }

            // Serialize response, and sent it across.
            newMsg.value = res.serializeToJson();
            server.send( newMsg );
        }

        return registerInternalMessageHandler( key, &handler );
    }
    static assert(is(typeof( registerEventHandler( "key", ( string data ) { } ) )));
    static assert(is(typeof( registerEventHandler( "key", ( string data ) => data ) )));

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
                warningf( "Invalid editor event received with key %s", event.key );
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
        if( id.empty )
        {
            error( "Callback received with empty id" );
        }
        else if( auto cb = id in callbacks )
        {
            (*cb)( msg );
            callbacks.remove( id );
        }
        else
        {
            errorf( "Callback reference lost: %s", id );
        }
    }

private:
    EventMessage[] pendingEvents;
    EventHandlerTuple[][string] eventHandlers;
    InternalEventHandler[UUID] callbacks;
}

/// Easy to handle response struct.
private struct EventResponse
{
    /// Status of a request
    enum Status
    {
        ok = 0,
        error = 2,
    }

    Status status;
    Json data;
}

// Exception that can be serialized
struct TransferableException
{
    string msg;
    size_t line;
    string file;

    static TransferableException fromException( Exception e )
    {
        TransferableException except;
        except.msg = e.msg;
        except.line = e.line;
        except.file = e.file;
        return except;
    }

    Exception toException()
    {
        return new Exception( msg, file, line );
    }
}
