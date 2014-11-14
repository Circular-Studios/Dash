module dash.utility.profiler;

// Enable profiler in debug mode.
debug version = DashUseProfiler;

version( DashUseProfiler ):
import tharsis.prof;
public import tharsis.prof: Zone;

abstract final class DashProfiler
{
static:
public:
    Profiler profiler;

    static this()
    {
        profiler = new Profiler( profileData[] );
    }

    void update() @nogc
    {
        if( profiler.outOfSpace )
            profiler.reset();
    }

    Zone startZone( string name ) @nogc
    {
        return Zone( profiler, name );
    }

    EventRange eventRange() @property @nogc
    {
        return profiler.profileData.eventRange;
    }

private:
    ubyte[Profiler.maxEventBytes * 1024] profileData;
}
