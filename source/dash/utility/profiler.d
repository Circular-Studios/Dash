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

            DGame.instance.editor.send( "dash:perf:zone_data", tharsis.profileData.zoneRange.map!( z => DashZone( z ) ) .array );

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

private struct DashZone
{
    uint id;
    uint parentID;
    ushort nestLevel;
    ulong startTime;
    ulong duration;
    string info;
    ulong endTime;

    this( ZoneData zone )
    {
        import std.conv: to;
        id = zone.id;
        parentID = zone.parentID;
        nestLevel = zone.nestLevel;
        startTime = zone.startTime;
        duration = zone.duration;
        info = zone.info.to!string;
        endTime = zone.endTime;
    }
}
