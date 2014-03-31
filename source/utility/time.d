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
		// For first run
		if( cast()cur == SysTime.min )
			cast()cur = (cast()prev) = Clock.currTime;

		delta = cast()cur - cast()prev;
		cast()total += cast()delta;

		debug
		{
			++frameCount;
			cast()second += cast()delta;
			if( cast()second >= 1.seconds )
			{
				log( OutputType.Info, "Framerate: ", frameCount );
				cast()second = Duration.zero;
				frameCount = 0;
			}
		}

		cast()prev = cur;
		cast()cur = Clock.currTime;
	}

private:
	SysTime cur;
	SysTime prev;
	Duration delta;
	Duration total;
	Duration second;
	int frameCount;
	
	/**
	 * Initialize the time controller with initial values.
	 */
	shared this()
	{
		cur = prev = SysTime.min;
		cast()second = cast()total = cast()delta = Duration.zero;
		frameCount = 0;
	}
}
