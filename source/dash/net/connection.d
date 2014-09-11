module dash.net.connection;
import dash.net.webconnection, dash.net.packets;

import msgpack;
import core.time, core.sync.mutex;
import std.concurrency, std.traits, std.conv, std.stdio;

enum typeName( T ) = fullyQualifiedName!( Unqual!( T ) );

template ordFuncs( T )
{
	shared void delegate( T data )[][shared Connection] ordFuncs;
}

shared class Connection
{
public:
	static shared(Connection) open( string ipAddress, bool host, ConnectionType[] types... )
	{
		assert( types.length > 0, "Please give more than 0 args." );

		auto conn = new shared Connection;

		foreach( type; types )
		{
			switch ( type )
			{
				case ConnectionType.TCP:
					conn.connections[ ConnectionType.TCP ] = new shared TCPConnection( ipAddress, host );
					break;

				case ConnectionType.UDP:
					conn.connections[ ConnectionType.UDP ] = new shared UDPConnection( ipAddress, host );
					break;

				default:
					break;
			}
		}

		// security and handshake stuff


		conn.startRecieve();
		conn._isOpen = true;

		return conn;
	}

	@property bool isOpen() { return _isOpen; }

	// Delegates for recieving data
	/// List of delegates to call when recieving a packet of type T
	ref shared(void delegate( T )[]) onReceiveData( T )()
	{
		// Function that handles data and calls events
		void callData( T )( ubyte[] data )
		{
			auto result = unpack!T( data );
			foreach( dta; onReceiveData!T )
				dta( result );
		}

		if( !( this in ordFuncs!T ) )
			ordFuncs!T[ this ] = [];

		if( typeName!T !in onReceiveFuncs )
			onReceiveFuncs[ typeName!T ] = &callData!T;

		return ordFuncs!T[ this ];
	}

	void login( string username, ConnectionType type = ConnectionType.TCP )
	{
		auto pack = new LoginPacket;
		pack.username = username;

		Packer packer;
		packer.pack( PacketType.Login );
		packer.pack( pack );

		// only for steve's chat server
		auto buffer = packer.stream.data;
		buffer[1] = cast(ubyte)(buffer[2] - 0xa0);
		buffer[2] = 0;

		connections[ type ].send( buffer );
	}

	void logoff( string username, ConnectionType type = ConnectionType.TCP )
	{
		auto pack = new LogoffPacket;
		pack.username = username;

		Packer packer;
		packer.pack( PacketType.Logoff );
		packer.pack( pack );

		connections[ type ].send( packer.stream.data );
	}

	void whisper( string target, string message, ConnectionType type = ConnectionType.TCP )
	{
		auto pack = new WhisperPacket;
		pack.target = target;
		pack.message = message;

		Packer packer;
		packer.pack( PacketType.Whisper );
		packer.pack( pack );

		connections[ type ].send( packer.stream.data );
	}

	void send( T... )( T args, ConnectionType type = ConnectionType.TCP ) if ( T.length > 0 )
	{
		foreach( ii, arg; args )
		{
			PacketType packetType;

			packetType = PacketType.Data;

			Packer packer;
			packer.pack( packetType );

			switch( packetType )
			{
				/*case PacketType.Handshake:
					auto hspack = new HandshakePacket;

					// Assign values

					packer.pack( hspack );
					break;*/

				case PacketType.Data:
					auto dpack = new DataPacket;

					dpack.type = typeName!(typeof(arg));
					dpack.data = pack( arg );

					packer.pack( dpack );
					break;

				default:
					assert( false, "Packet type not defined in switch." );
			}

			connections[ type ].send( packer.stream.data );
		}
	}

	void update()
	{
		synchronized( this )
		{
			if( buffer.length )
			{
				packets ~= buffer;
				buffer = [];
			}
		}

		// Return if not open
		if( !isOpen )
			return;

		foreach( buf; packets )
		{
			if( !buf.length )
			{
				close();
				throw new Exception( "Connection Closed" );
			}

			auto unpacker = Unpacker( cast(ubyte[])buf );

			PacketType packType;
			unpacker.unpack( packType );

			switch( packType )
			{
				/*case PacketType.Handshake:
					HandshakePacket pack;
					unpacker.unpack( pack );
					break;*/

				case PacketType.Data:
					DataPacket pack;
					unpacker.unpack( pack );

					if( pack.type in onReceiveFuncs )
						onReceiveFuncs[ pack.type ]( pack.data );
					else
						writeln( "No onRecieveData event for ", pack.type );

					break;

				default:
					//assert( false, "Packet type not defined in switch." );
			}
		}

		packets = [];
	}

	void close()
	{
		foreach( thread; childrenThreads )
			std.concurrency.send( cast(Tid)thread, "done" );

		foreach( conn; connections )
			conn.close();

		_isOpen = false;
	}

private:
	WebConnection[ ConnectionType ] connections;
	void delegate( ubyte[] )[string] onReceiveFuncs;
	Tid[] childrenThreads;
	bool _isOpen;
	ubyte[][] packets;
	ubyte[][] buffer;

	void startRecieve()
	{
		foreach( web; connections )
		{
			childrenThreads ~= cast(shared)spawn( ( ref shared(Connection) conn, shared WebConnection webcon )
			{
				shared(ubyte[]) buf = new shared(ubyte[ 1024 ]);

				while( true )
				{
					webcon.recv( buf );

					if( receiveTimeout( dur!"msecs"( 0 ), (string x) { } ) )
						break;

					synchronized( conn )
					{
						conn.buffer ~= buf.dup;
					}
				}
			}, this, web );
		}
	}
}
