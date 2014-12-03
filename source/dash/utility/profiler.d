module dash.utility.profiler;

// Enable profiler in debug mode.
debug version = DashUseProfiler;

version( DashUseProfiler ):
import tharsis.prof;
public import tharsis.prof: Zone;

abstract class DashProfiler
{
static:
public:
    void initialize()
    {
        tharsis = new Profiler( profileData[] );
    }

    void update()
    {
        import std.array: array;
        import dash.core.dgame: DGame;

        DGame.instance.editor.send( "dash:perf:zone_data", tharsis.profileData.zoneRange.array );

        tharsis.reset();
    }

    Zone startZone( string name )
    {
        return Zone( tharsis, name );
    }

private:
    Profiler tharsis;
    ubyte[Profiler.maxEventBytes * 1024] profileData;
}
