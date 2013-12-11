module utility.time;
import std.datetime;

class Time
{
static
{
public:
	@property float deltaTime() { return 0.016; }
	@property float totalTime() { return 1.00f; }

	void initialize()
	{

	}

	void update()
	{

	}

private:
	SysTime cur;
	SysTime prev;
	Duration delta;
	Duration total;
}
}