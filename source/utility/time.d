module utility.time;
import std.datetime;

static class Time
{
static:
public:
	/**
	 * Time since last frame, in seconds.
	 */
	@property float deltaTime() { return 0.016; }
	/**
	 * Total time spent running, in seconds.
	 */
	@property float totalTime() { return 1.00f; }

	/**
	 * Initialize the time controller with initial values.
	 */
	static this()
	{
		cur = prev = Clock.currTime;
		total = delta = 0.0f;
	}

	/** ditto */
	deprecated void initialize()
	{
		cur = prev = Clock.currTime;
		total = delta = 0.0f;
	}

	/**
	 * Update the times. Only call once per frame!
	 */
	void update()
	{
		delta = ( cur - prev ).get!"seconds";
		total += delta;

		prev = cur;
		cur = Clock.currTime;
	}

private:
	SysTime cur;
	SysTime prev;
	float delta;
	float total;
}
