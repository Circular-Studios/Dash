module dash.net.connectionmanager;
import dash.net;

import core.time;
import std.concurrency, std.parallelism, std.stdio;

shared class ConnectionManager
{
public:
	static shared(ConnectionManager) open()
	{
		auto conman = new shared ConnectionManager;

		conman.closing = false;

		return conman;
	}

	void delegate( shared Connection )[] onNewConnection;

	void send( T... )( T args, ConnectionType type = ConnectionType.TCP ) if ( T.length > 0 )
	{
		foreach( conn; parallel( cast()connections.dup ) )
		{
			conn.send( args, type );
		}
	}

	void start()
	{
		spawn( &startReceive, this );
	}

	void close()
	{
		// Open a connection to this to stop blocking operation of waiting for a new thread.
		closing = true;
		Connection.open( "127.0.0.1", false, ConnectionType.TCP );

		foreach( thread; childrenThreads )
			std.concurrency.send( cast(Tid)thread, "done" );

		foreach( conn; connections )
			conn.close();
	}

	@property shared(Connection[]) connections() { return _connections; }

private:
	Connection[] _connections;
	Tid[] childrenThreads;
	bool closing;

	this() { }

	static void startReceive( shared ConnectionManager conman )
	{
		writeln( "Waiting for new connection." );
		auto newCon = Connection.open( "localhost", true, ConnectionType.TCP );

		synchronized( conman )
		{
            foreach( event; conman.onNewConnection )
            {
                event( newCon );
            }

			conman._connections ~= newCon;
		}

		if( conman.closing )
			return;

		++conman.childrenThreads.length;
		conman.childrenThreads[ $-1 ] = cast(shared)spawn( &startReceive, conman );

		while( true )
		{
			if( receiveTimeout( dur!"msecs"( 0 ), (string x) { } ) )
				break;

			try
			{
				newCon.update();
			}
			catch
			{
				synchronized( conman )
				{
					import std.algorithm;
					auto thisIdx = (cast(Connection[])conman.connections).countUntil( cast()newCon );
					// Get tasks after one being removed
					auto end = conman.connections[ thisIdx+1..$ ];
					// Get tasks before one being removed
					conman._connections = conman.connections[ 0..thisIdx ];
					// Add end back
					conman._connections ~= end;

                    writeln( "Connection ", thisIdx, " closed." );
				}

				return;
			}
		}
	}
}
