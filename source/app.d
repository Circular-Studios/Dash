module app;
import dash.core.dgame;

import std.stdio;

version( unittest ) { }
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
