module app;
import core.dgame;

import std.stdio;

void main()
{
	if( !DGame.instance )
	{
		writeln( "No game supplied." );
		return;
	}

	DGame.instance.run();
}
