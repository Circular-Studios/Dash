module dash.editor.websockets;
import dash.editor.editor;
import dash.utility.output, dash.utility.config;

import vibe.core.core;
import vibe.http.websockets, vibe.http.server, vibe.http.router;
import vibe.data.json;
import core.time;

struct WebSocketServer
{
public:
    void start( Editor editor )
    {
        this.editor = editor;

        auto router = new URLRouter;
        router.get( "/" ~ config.editor.route, handleWebSockets( &handleConnection ) );

        auto settings = new HTTPServerSettings;
        settings.port = config.editor.port;
        settings.bindAddresses = [ "::1", "127.0.0.1" ];

        listenHTTP( settings, router );
    }

    void update()
    {
        processEvents();

        // Process messages
        string[] jsonStrings;

        if( incomingBuffers.length )
        {
            synchronized( incomingBuffersMutex )
            {
                // Copy the jsons.
                foreach( buffer; incomingBuffers )
                {
                    jsonStrings ~= cast(string)buffer.dup;
                }

                // Clear buffers
                incomingBuffers.length = 0;    
            }
        }

        foreach( jsonStr; jsonStrings )
        {
            EventMessage msg;
            try msg = jsonStr.deserializeJson!EventMessage();
            catch( JSONException e )
            {
                errorf( "Invalid json string sent: %s", jsonStr );
                continue;
            }

            if( msg.key.length == 0 )
            {
                warning( "Received a packet without a \"key.\"" );
                continue;
            }
            if( msg.value.type == Json.Type.null_ || msg.value.type == Json.Type.undefined )
            {
                warning( "Received a packet without a \"value.\"" );
                continue;
            }

            editor.queueEvent( msg );
        }
    }

    void send( EventMessage msg )
    {
        shared string jsonStr = msg.serializeToJsonString();

        synchronized( outgoingBuffersMutex )
        {
            outgoingBuffers ~= jsonStr;
        }
    }

    void stop()
    {
        exitEventLoop( true );
    }

private:
    Editor editor;
}

package:
/// The type-safe form the cross layer communcations should take
struct EventMessage
{
    string key;
    Json value;
    string callbackId;
}

private:
// Received messages to be processed
shared string[] incomingBuffers;
shared string[] outgoingBuffers;

shared class Mutex { }
shared Mutex incomingBuffersMutex;
shared Mutex outgoingBuffersMutex;

shared static this()
{
    incomingBuffersMutex = new shared Mutex();
    outgoingBuffersMutex = new shared Mutex();
}

void handleConnection( scope WebSocket socket )
{
    size_t outgoingMessagesSent = outgoingBuffers.length;

    while( socket.connected )
    {
        // If there's messages waiting
        while( socket.waitForData( 100.msecs ) )
        {
            string msg = socket.receiveText();
            synchronized( incomingBuffersMutex )
            {
                incomingBuffers ~= msg[];
            }
        }

        // If we need to send a message
        if( outgoingBuffers.length > outgoingMessagesSent )
        {
            shared string[] myOutgoing;
            synchronized( outgoingBuffersMutex )
            {
                // Copy the buffers to be thread local
                myOutgoing = outgoingBuffers[ outgoingMessagesSent..outgoingBuffers.length ].dup;
                // Update current index.
                outgoingMessagesSent = outgoingBuffers.length;
            }

            // And send them.
            foreach( buf; myOutgoing )
            {
                socket.send( buf );
            }
        }
    }
}
