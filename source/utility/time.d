/**
 * Defines the static Time class, which manages all game time related things.
 */
module utility.time;
import utility.output;

import std.datetime, core.atomic;

/**
 * Manages time and delta time.
 */
shared final struct Time
{
public static:
    /**
     * Time since last frame.
     */
    @property const Duration deltaTime() { return delta; }
    /**
     * Total time spent running.
     */
    @property const Duration totalTime() { return total; }

    /**
     * Update the times. Only call once per frame!
     */
    void update()
    {
        updateTime();
    }

private:
    Duration delta;
    Duration total;
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
    second = total = delta = Duration.zero;
    frameCount = 0;

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
    Time.delta = delta;
    Time.total += delta;
}
