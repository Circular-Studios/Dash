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

        // Default port to 8080
        ushort bindPort = 8080;
        config.tryFind( "Editor.Port", bindPort );

        auto router = new URLRouter;
        router.get( "/ws", handleWebSockets( &handleConnection ) );

        auto settings = new HTTPServerSettings;
        settings.port = bindPort;
        settings.bindAddresses = [ "::1", "127.0.0.1" ];

        listenHTTP( settings, router );
    }

    void update()
    {
        processEvents();

        // Process messages
        string[] jsonStrings;

        synchronized( incomingBuffersMutex )
        {
            // Copy the jsons.
            foreach( buffer; incomingBuffers )
            {
                jsonStrings ~= cast(string)buffer[];
            }

            // Clear buffers
            incomingBuffers.length = 0;
        }

        foreach( jsonStr; jsonStrings )
        {
            EventMessage msg;
            try msg = jsonStr.deserializeJson!EventMessage();
            catch( JSONException e )
            {
                logError( "Invalid json string sent: ", jsonStr );
                continue;
            }

            if( msg.key.length == 0 )
            {
                logWarning( "Received a packet without a \"key.\"" );
                continue;
            }
            if( msg.value.type == Json.Type.null_ || msg.value.type == Json.Type.undefined )
            {
                logWarning( "Received a packet without a \"value.\"" );
                continue;
            }

            editor.queueEvent( msg );
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
    size_t outgoingMessagesSent = 0;

    while( socket.connected )
    {
        //if( socket.dataAvailableForRead )
        {
            string msg = socket.receiveText();
            synchronized( incomingBuffersMutex ) incomingBuffers ~= msg[];
        }
        /*else*/ if( outgoingBuffers.length > outgoingMessagesSent )
        {
            synchronized( outgoingBuffersMutex )
            {
                foreach( i; outgoingMessagesSent..outgoingBuffers.length )
                {
                    socket.send( outgoingBuffers[ i ] );
                }

                outgoingMessagesSent = outgoingBuffers.length;
            }
        }
    }
}
