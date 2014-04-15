/**
 * Defines the static Time class, which manages all game time related things.
 */
module utility.time;
import utility;

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
    return cast(float)dur.fracSec.hnsecs / cast(float)1.convert!( "seconds", "hnsecs" );
}

shared TimeManager Time;

shared static this()
{
    Time = new shared TimeManager;
}

/**
 * Manages time and delta time.
 */
shared final class TimeManager
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
    }

private:
    this() { }
}

private:
StopWatch sw;
TickDuration cur;
TickDuration prev;
Duration delta;
Duration total;

debug
{
    Duration second;
    int frameCount;
}

/**
 * Initialize the time controller with initial values.
 */
static this()
{
    cur = prev = TickDuration.min;
    total = delta = Duration.zero;

    debug
    {
        second = Duration.zero;    
        frameCount = 0;
    }

    Time.delta = Time.total = Duration.min;
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

    debug
    {
        ++frameCount;
        second += delta;
        if( second >= 1.seconds )
        {
            logInfo( "Framerate: ", frameCount );
            second = Duration.zero;
            frameCount = 0;
        }
    }

    prev = cur;
    cur = sw.peek();

    // Pass to shared values
    cast()Time.delta = delta;
    cast()Time.total += delta;
}
