/**
 * Defines the static Time class, which manages all game time related things.
 */
module dash.utility.time;
import dash.utility;

import std.datetime;

/**
 * Converts a duration to a float of seconds.
 * 
 * Params:
 *  dur =           The duration to convert.
 *
 * Returns: The duration in seconds.
 */
float toSeconds( Duration dur )
{
    return cast(float)dur.total!"hnsecs" / cast(float)1.convert!( "seconds", "hnsecs" );
}

TimeManager Time;

static this()
{
    Time = new TimeManager;
}

/**
 * Manages time and delta time.
 */
final class TimeManager
{
private:
    Duration delta;
    Duration total;
    
public:
    /**
     * Time since last frame in seconds.
     */
    @property float deltaTime() { return delta.toSeconds; }
    /**
     * Total time spent running in seconds.
     */
    @property float totalTime() { return total.toSeconds; }

    /**
     * Update the times. Only call once per frame!
     */
    void update()
    {
        assert( onMainThread, "Must call Time.update from main thread." );

        updateTime();

        import dash.core.dgame: DGame;
        DGame.instance.editor.send( "dash:perf:frametime", deltaTime );
    }

private:
    this()
    {
        delta = total = Duration.zero;
    }
}

private:
StopWatch sw;
TickDuration cur;
TickDuration prev;
Duration delta;
Duration total;
Duration second;
int frameCount;

/**
 * Initialize the time controller with initial values.
 */
static this()
{
    cur = prev = TickDuration.min;
    total = delta = second = Duration.zero;
    frameCount = 0;
}

/**
 * Thread local time update.
 */
void updateTime()
{
    if( !sw.running )
    {
        sw.start();
        cur = prev = sw.peek();
    }

    delta = cast(Duration)( cur - prev );

    prev = cur;
    cur = sw.peek();

    // Pass to values
    Time.total = cast(Duration)cur;
    Time.delta = delta;

    // Update framerate
    ++frameCount;
    second += delta;
    if( second >= 1.seconds )
    {
        tracef( "Framerate: %d", frameCount );
        second = Duration.zero;
        frameCount = 0;
    }
}
