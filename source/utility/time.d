module utility.time;
import std.datetime;

static class Time
{
static:
public:
	export @property float deltaTime() { return 0.016; }
	export @property float totalTime() { return 1.00f; }

	export void initialize()
	{

	}

	export void update()
	{
		
	}

private:
	SysTime cur;
	SysTime prev;
	Duration delta;
	Duration total;
}
