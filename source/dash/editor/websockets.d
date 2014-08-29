module dash.editor.websockets;
import dash.editor.editor;
import dash.utility.output;

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
        router.get( "/ws", handleWebSockets( &handleConnection ) );

        auto settings = new HTTPServerSettings;
        settings.port = 8080;
        settings.bindAddresses = [ "::1", "127.0.0.1" ];

        listenHTTP( settings, router );
    }

    void update()
    {
        processEvents();

        // Process messages
        Json[] jsons;
        synchronized( buffersMutex )
        {
            // Clear buffers
            scope(exit) buffers.length = 0;

            // Parse the jsons.
            foreach( buffer; buffers )
            {
                string jsonStr = cast(string)buffer[];
                jsons ~= parseJson( jsonStr );
            }
        }

        import std.stdio;
        if( jsons.length )
            writefln( "Received %s jsons.", jsons.length );

        foreach( json; jsons )
        {
            string key;
            Json value;
            if( auto keyPtr = "key" in json )
                key = keyPtr.to!string;
            else
                logWarning( "Received a packet without a \"key.\"" );

            if( auto valuePtr = "value" in json )
                value = *valuePtr;
            else
                logWarning( "Received a packet without a \"value.\"" );

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
shared string[] buffers;
shared class Mutex { }
shared Mutex buffersMutex;
shared static this()
{
    buffersMutex = new shared Mutex();
}

void handleConnection( scope WebSocket sock )
{
    while( sock.connected )
    {
        string msg = sock.receiveText();

        synchronized( buffersMutex ) buffers ~= msg[];

        import std.stdio, std.conv;
        writeln( "Message received! ", msg.to!string );

        sock.send( msg );
    }
}
