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
	 * Time since last frame, in seconds.
	 */
	final @property const float deltaTime() { return delta; }
	/**
	 * Total time spent running, in seconds.
	 */
	final @property const float totalTime() { return totalTime; }

	/**
	 * Update the times. Only call once per frame!
	 */
	synchronized final void update()
	{
		delta = ( cast()cur - cast()prev ).fracSec.nsecs / 1_000_000_000.0f;
		total += delta;

		debug
		{
			++frameCount;
			second += delta;
			if( second >= 1.0f )
			{
				log( OutputType.Info, "Framerate: ", frameCount );
				second = frameCount = 0;
			}
		}

		(cast()prev) = cur;
		(cast()cur) = Clock.currTime;
	}

private:
	SysTime cur;
	SysTime prev;
	float delta;
	float total;
	float second;
	int frameCount;
	
	/**
	 * Initialize the time controller with initial values.
	 */
	shared this()
	{
		cur = prev = Clock.currTime;
		second = total = delta = 0.0f;
		frameCount = 0;
	}
}
