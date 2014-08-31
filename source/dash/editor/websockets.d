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
            // Clear buffers
            scope(exit) incomingBuffers.length = 0;

            // Copy the jsons.
            foreach( buffer; incomingBuffers )
            {
                string jsonString = cast(string)buffer[];
            }
        }

        foreach( jsonStr; jsonStrings )
        {
            Json json;
            try json = jsonStr.parseJson();
            catch( JSONException e )
            {
                logError( "Invalid json string sent: ", jsonStr );
                continue;
            }

            string key;
            Json value;
            if( auto keyPtr = "key" in json )
            {
                key = keyPtr.to!string;
            }
            else
            {
                logWarning( "Received a packet without a \"key.\"" );
                continue;
            }

            if( auto valuePtr = "value" in json )
            {
                value = *valuePtr;
            }
            else
            {
                logWarning( "Received a packet without a \"value.\"" );
                continue;
            }

            editor.queueEvent( key, value );
        }
    }

    void stop()
    {
        exitEventLoop( true );
    }

private:
    Editor editor;
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
    while( socket.connected )
    {
        //if( socket.dataAvailableForRead )
        {
            string msg = socket.receiveText();
            synchronized( incomingBuffersMutex ) incomingBuffers ~= msg[];
        }
        //else if( outgoingBuffers.length )
        {
            // TODO: Send message
        }
    }
}
