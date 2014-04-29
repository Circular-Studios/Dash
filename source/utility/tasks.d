/**
 * Defines methods for scheduling tasks with different conditions for executing.
 *
 */
module utility.tasks;
import utility.time, utility.output;

import gl3n.util: is_vector, is_matrix, is_quaternion;
import gl3n.interpolate: lerp;

import core.time;
import std.algorithm: min;
import std.parallelism: parallel;

public:
/**
 * Schedule a task to be executed until it returns true.
 *
 * Params:
 *  dg =                The task to execute
 */
void scheduleTask( bool delegate() dg )
{
    scheduledTasks ~= dg;
}

/**
 * Schedule a task to interpolate a value over a period of time.
 *
 * Params:
 *  val =               [ref] The value to interpolate
 *  start =             The starting value for interpolation
 *  end =               The target value for interpolation
 *  interpFunc =        [default=lerp] The function to use for interpolation
 *
 * Example:
 * ---
 * scheduleInterpolateTask( transform.position, startNode, endNode, 100.msecs );
 * ---
 */
void scheduleInterpolateTask(T)( ref T val, T start, T end, Duration duration, T function( T, T, float ) interpFunc = &lerp!T ) if( is_vector!T || is_quaternion!T )
{
    auto startTime = Time.totalTime;
    scheduleTimedTask( duration, ( elapsed )
    {
        val = interpFunc( start, end, elapsed / duration.toSeconds );
    } );
}
///
unittest
{
    import std.stdio;
    import gl3n.linalg;

    writeln( "Dash Tasks scheduleInterpolateTask unittest 1" );

    shared vec3 interpVec = shared vec3( 0, 0, 0 );
    shared vec3 start = shared vec3( 0, 1, 0 );
    shared vec3 end = shared vec3( 0, 1, 1 );
    scheduleInterpolateTask( interpVec, start, end, 100.msecs );

    while( scheduledTasks.length )
        executeTasks();

    assert( interpVec == end );
}

/**
 * Schedule a task to interpolate a property over a period of time.
 *
 * Params:
 *  prop =              The name of the property being interpolated
 *  own =               [ref] The owner of the property
 *  start =             The starting value for interpolation
 *  end =               The target value for interpolation
 *  interpFunc =        [default=lerp] The function to use for interpolation
 *
 * Example:
 * ---
 * scheduleInterpolateTask( transform.position, startNode, endNode, 100.msecs );
 * ---
 */
void scheduleInterpolateTask( string prop, T, Owner )( ref Owner own, T start, T end, Duration duration, T function( T, T, float ) interpFunc = &lerp!T )
    if( ( is_vector!T || is_quaternion!T ) && __traits( compiles, mixin( "own." ~ prop ) ) )
{
    auto startTime = Time.totalTime;
    scheduleTimedTask( duration, ( elapsed )
    {
        mixin( "own." ~ prop ~ " = interpFunc( start, end, elapsed / duration.toSeconds );" );
    } );
}
///
unittest
{
    import std.stdio;
    import gl3n.linalg;

    writeln( "Dash Tasks scheduleInterpolateTask unittest 2" );

    auto testClass = new TestPropertyInterpolate;
    testClass.vector = shared vec3( 0, 0, 0 );
    shared vec3 start = shared vec3( 0, 1, 0 );
    shared vec3 end = shared vec3( 0, 1, 1 );
    scheduleInterpolateTask!q{vector}( testClass, start, end, 100.msecs );

    while( scheduledTasks.length )
        executeTasks();

    assert( testClass.vector == end );
}
version( unittest )
class TestPropertyInterpolate
{
    import gl3n.linalg;

    private shared vec3 _vector;
    public @property shared(vec3) vector() { return _vector; }
    public @property void vector( shared vec3 newVal ) { _vector = newVal; }
}

/**
 * Schedule a task to be executed until the duration expires.
 *
 * Params:
 *  duration =          The duration to execute the task for
 *  dg =                The task to execute
 */
void scheduleTimedTask( Duration duration, void delegate() dg )
{
    auto startTime = Time.totalTime;
    scheduleTask( {
        dg();
        return Time.totalTime >= startTime + duration.toSeconds;
    } );
}

/// ditto
void scheduleTimedTask( Duration duration, void delegate( float ) dg )
{
    auto startTime = Time.totalTime;
    scheduleTask( {
        dg( min( Time.totalTime - startTime, duration.toSeconds ) );
        return Time.totalTime >= startTime + duration.toSeconds;
    } );
}

/// ditto
void scheduleTimedTask( Duration duration, void delegate( float, float ) dg )
{
    auto startTime = Time.totalTime;
    scheduleTask( {
        dg( min( Time.totalTime - startTime, duration.toSeconds ), duration.toSeconds );
        return Time.totalTime >= startTime + duration.toSeconds;
    } );
}

/// ditto
void scheduleTimedTask( Duration duration, bool delegate() dg )
{
    auto startTime = Time.totalTime;
    scheduleTask( {
        if( dg() )
            return true;
        else
            return Time.totalTime >= startTime + duration.toSeconds;
    } );
}

/// ditto
void scheduleTimedTask( Duration duration, bool delegate( float ) dg )
{
    auto startTime = Time.totalTime;
    scheduleTask( {
        if( dg( min( Time.totalTime - startTime, duration.toSeconds ) ) )
            return true;
        else
            return Time.totalTime >= startTime + duration.toSeconds;
    } );
}

/// ditto
void scheduleTimedTask( Duration duration, bool delegate( float, float ) dg )
{
    auto startTime = Time.totalTime;
    scheduleTask( {
        if( dg( min( Time.totalTime - startTime, duration.toSeconds ), duration.toSeconds ) )
            return true;
        else
            return Time.totalTime >= startTime + duration.toSeconds;
    } );
}

/**
 * Schedule a task to be executed until the duration expires.
 *
 * Params:
 *  dg =                The task to execute
 *  duration =          The duration to execute the task for
 */
deprecated( "Use version with duration as first parameter." )
void scheduleTimedTask( void delegate() dg, Duration duration )
{
    auto startTime = Time.totalTime;
    scheduleTask( {
        dg();
        return Time.totalTime >= startTime + duration.toSeconds;
    } );
}

/**
 * Schedule a task to be execuated after the specified amount of time.
 *
 * Params:
 *  delay =             The ammount of time to wait before executing
 *  dg =                The task to execute
 */
void scheduleDelayedTask( Duration delay, void delegate() dg )
{
    auto startTime = Time.totalTime;
    scheduleTask( {
        if( Time.totalTime - startTime >= delay.toSeconds )
        {
            dg();
            return true;
        }
        else
        {
            return false;
        }
    } );
}

/**
 * Schedule a task to be execuated after the specified amount of time.
 *
 * Params:
 *  dg =                The task to execute
 *  delay =             The ammount of time to wait before executing
 */
deprecated( "Use version with delay as first parameter." )
void scheduleDelayedTask( void delegate() dg, Duration delay )
{
    auto startTime = Time.totalTime;
    scheduleTask( {
        if( Time.totalTime - startTime >= delay.toSeconds )
        {
            dg();
            return true;
        }
        else
        {
            return false;
        }
    } );
}

/**
 * Schedule a task to be executed on an interval, until the task returns true.
 *
 * Params:
 *  interval =          The interval on which to call this task.
 *  dg =                The task to execute.
 */
void scheduleIntervaledTask( Duration interval, bool delegate() dg )
{
    auto startTime = Time.totalTime;
    auto timeTilExe = interval.toSeconds;
    scheduleTask( {
        timeTilExe -= Time.deltaTime;
        if( timeTilExe <= 0 )
        {
            if( dg() )
                return true;

            timeTilExe = interval.toSeconds;
        }

        return false;
    } );
}

/**
 * Schedule a task to be executed on an interval a given number of times.
 *
 * Params:
 *  interval =          The interval on which to call this task.
 *  numExecutions =     The number of time to execute the task.
 *  dg =                The task to execute.
 */
void scheduleIntervaledTask( Duration interval, uint numExecutions, void delegate() dg )
{
    auto startTime = Time.totalTime;
    auto timeTilExe = interval.toSeconds;
    uint executedTimes = 0;
    scheduleTask( {
        timeTilExe -= Time.deltaTime;
        if( timeTilExe <= 0 )
        {
            dg();

            ++executedTimes;
            timeTilExe = interval.toSeconds;
        }

        return executedTimes == numExecutions;
    } );
}

/**
 * Schedule a task to be executed on an interval a given number of times, or until the event returns true.
 *
 * Params:
 *  interval =          The interval on which to call this task.
 *  numExecutions =     The number of time to execute the task.
 *  dg =                The task to execute.
 */
void scheduleIntervaledTask( Duration interval, uint numExecutions, bool delegate() dg )
{
    auto startTime = Time.totalTime;
    auto timeTilExe = interval.toSeconds;
    uint executedTimes = 0;
    scheduleTask( {
        timeTilExe -= Time.deltaTime;
        if( timeTilExe <= 0 )
        {
            if( dg() )
                return true;

            ++executedTimes;
            timeTilExe = interval.toSeconds;
        }

        return executedTimes == numExecutions;
    } );
}

/**
 * Executes all scheduled tasks.
 */
void executeTasks()
{
    size_t[] toRemove;    // Indicies of tasks which are done
    foreach( i, task; parallel( scheduledTasks ) )
    {
        if( task() )
            synchronized toRemove ~= i;
    }
    foreach_reverse( i; toRemove )
    {
        // Get tasks after one being removed
        auto end = scheduledTasks[ i+1..$ ];
        // Get tasks before one being removed
        scheduledTasks = scheduledTasks[ 0..i ];
        // Add end back
        scheduledTasks ~= end;
    }
}

/**
 * Cancels all running tasks.
 */
void resetTasks()
{
    scheduledTasks = [];
}

private:
/// The tasks that have been scheduled
bool delegate()[] scheduledTasks;
