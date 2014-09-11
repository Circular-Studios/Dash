module dash.net.webconnection;

import std.socket, std.bitmanip, std.stdio;

enum ConnectionType : ushort
{
	TCP = 0x01,
	UDP = 0x02,
}

immutable ubyte[] terminator = [ 0, 0, 0, 0 ];

package abstract class WebConnection
{
	const ConnectionType type;

	abstract shared void send( const ubyte[] args );
	shared bool recv( ref shared ubyte[] buf )
	{
		ubyte[] tempBuf = new ubyte[ 1024 ];
		buf.length = 0;

		do
		{
			auto size = (cast(Socket)socket).receive( tempBuf );

			if( size <= 0 )
				return false;

			tempBuf.length = size;

			buf ~= tempBuf;
		} while( cast(ubyte[])buf[ $-terminator.length..$ ] != terminator );



		return true;
	}
	abstract shared void close();

	Socket socket;

protected:
	shared protected this( ConnectionType type )
	{
		this.type = type;
	}
}

package class TCPConnection : WebConnection
{
	shared static TcpSocket listener;

	shared this( string address, bool host )
	{
		super( ConnectionType.TCP );

		if( host )
		{
			if( listener is null )
			{
				auto tmplistener = new TcpSocket;
				tmplistener.bind( new InternetAddress( 8080 ) );
				tmplistener.listen( 10 );
				listener = cast(shared)tmplistener;
			}

			auto tmp = (cast()listener).accept();
			writeln( "TCP Connection accepted." );
			socket = cast(shared)tmp;
		}
		else
		{
			socket = cast(shared) new TcpSocket( new InternetAddress( address, 8080 ) );
		}
	}

	shared static ~this()
	{
		if( listener )
			(cast()listener).close();
	}

	override shared void send( const ubyte[] args )
	{
		auto sizeSent = (cast(Socket)socket).send( args ~ terminator );

		assert( args.length + terminator.length == sizeSent, "Not all bytes sent." );
	}

	override shared void close()
	{
		(cast(Socket)socket).close();
	}
}

package class UDPConnection : WebConnection
{
	InternetAddress address;

	shared this( string addr, bool host )
	{
		super( ConnectionType.UDP );

		address = cast(shared) new InternetAddress( addr, 8080 );
		socket = cast(shared) new UdpSocket();

		(cast(Socket)socket).bind( new InternetAddress( 8080 ) );
		(cast(Socket)socket).connect( cast(Address)address );
	}

	override shared void send( const ubyte[] args )
	{
		auto sizeSent = (cast(Socket)socket).sendTo( args ~ terminator, cast(Address)address );

		assert( args.length + terminator.length == sizeSent, "Not all bytes sent." );
	}

	override shared void close()
	{
		(cast(Socket)socket).close();
	}
}
