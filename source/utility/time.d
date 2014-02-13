/**
 * Defines the static Time class, which manages all game time related things.
 */
module utility.time;
import utility.output;

import std.datetime;

/**
 * Manages time and delta time.
 */
final abstract class Time
{
public static:
	/**
	 * Time since last frame, in seconds.
	 */
	final @property float deltaTime() { return 0.016; }
	/**
	 * Total time spent running, in seconds.
	 */
	final @property float totalTime() { return 1.00f; }

	/**
	 * Initialize the time controller with initial values.
	 */
	static this()
	{
		cur = prev = Clock.currTime;
		second = total = delta = 0.0f;
		frameCount = 0;
	}

	/**
	 * Update the times. Only call once per frame!
	 */
	final void update()
	{
		delta = ( cur - prev ).fracSec.nsecs / 1_000_000_000.0f;
		total += delta;

		debug
		{
			++frameCount;
			second += delta;
			if( second >= 1.0f )
			{
				Output.printValue( OutputType.Info, "Framerate", frameCount );
				second = frameCount = 0;
			}
		}

		prev = cur;
		cur = Clock.currTime;
	}

private:
	SysTime cur;
	SysTime prev;
	float delta;
	float total;
	float second;
	int frameCount;
}
