module utility.concurrency;

public import core.thread, std.concurrency, std.parallelism;

/// The ID of the main thread
@property Tid mainThread() { return cast()_mainThread; }
/// Returns true if called by main thread
@property bool onMainThread() { return thisTid == mainThread; }

shared static this()
{
    _mainThread = cast(shared)thisTid;
}

private shared Tid _mainThread;
