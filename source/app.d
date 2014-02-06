module app;
import core.dgame;

import std.stdio;

version( unittest )
{
	void main()
	{
		writeln( "Finished running unit tests." );
	}
}
else
{
	void main()
	{
		if( !DGame.instance )
		{
			writeln( "No game supplied." );
			return;
		}

		DGame.instance.run();
	}
}
