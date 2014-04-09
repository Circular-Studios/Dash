/**
 * Defines the static Time class, which manages all game time related things.
 */
module utility.time;
import utility.output;

import std.datetime;

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
public:
    /**
     * Time since last frame.
     */
    final @property const Duration deltaTime() { return delta; }
    /**
     * Total time spent running.
     */
    final @property const Duration totalTime() { return total; }

    /**
     * Update the times. Only call once per frame!
     */
    synchronized final void update()
    {
        if( !(cast()sw).running )
        {
            (cast()sw).start();
            cur = prev = (cast()sw).peek();
        }

        delta = cast(shared Duration)( cast()cur - cast()prev );

        debug
        {
            ++frameCount;
            cast()second += cast()delta;
            if( cast()second >= 1.seconds )
            {
                logInfo( "Framerate: ", frameCount );
                cast()second = Duration.zero;
                frameCount = 0;
            }
        }

        prev = cur;
        cur = (cast()sw).peek();
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
    shared this()
    {
        cur = prev = TickDuration.min;
        cast()second = cast()total = cast()delta = Duration.zero;
        frameCount = 0;
    }
}
