/**
 * Defines methods for scheduling tasks with different conditions for executing.
 *
 */
module dash.utility.tasks;
import dash.utility.time, dash.utility.output, dash.utility.math;

import core.time;
import std.algorithm: min;
import std.parallelism: parallel;
import std.uuid: UUID, randomUUID;
import std.typecons;

public:
/**
 * Schedule a task to be executed until it returns true.
 *
 * Params:
 *  dg =                The task to execute.
 *
 * Returns: The ID of the task.
 */
UUID scheduleTask( bool delegate() dg )
{
    auto id = randomUUID();
    scheduledTasks ~= tuple( dg, id );
    return id;
}

/**
 * Schedule a task to interpolate a value over a period of time.
 *
 * Params:
 *  T =                 The type to interpolate, either vector or quaternion.
 *  val =               [ref] The value to interpolate.
 *  start =             The starting value for interpolation.
 *  end =               The target value for interpolation.
 *  interpFunc =        [default=lerp] The function to use for interpolation.
 *
 * Returns: The ID of the task.
 *
 * Example:
 * ---
 * scheduleInterpolateTask( position, startNode, endNode, 100.msecs );
 * ---
 */
UUID scheduleInterpolateTask(T)( ref T val, T start, T end, Duration duration, T function( T, T, float ) interpFunc = &lerp!( T ) )// if( is_vector!T || is_quaternion!T )
{
    return scheduleTimedTask( duration, ( elapsed )
    {
        val = interpFunc( start, end, elapsed / duration.toSeconds );
    } );
}
///
unittest
{
    import std.stdio;

    writeln( "Dash Tasks scheduleInterpolateTask unittest 1" );

    vec3f interpVec = vec3f( 0, 0, 0 );
    vec3f start = vec3f( 0, 1, 0 );
    vec3f end = vec3f( 0, 1, 1 );
    scheduleInterpolateTask( interpVec, start, end, 100.msecs );

    while( scheduledTasks.length )
    {
        Time.update();
        executeTasks();
    }

    assert( interpVec == end );
}

/**
 * Schedule a task to interpolate a property over a period of time.
 *
 * Params:
 *  prop =              The name of the property being interpolated.
 *  T =                 The type to interpolate, either vector or quaternion.
 *  Owner =             The type that owns the property interpolating.
 *  own =               [ref] The owner of the property.
 *  start =             The starting value for interpolation.
 *  end =               The target value for interpolation.
 *  interpFunc =        [default=lerp] The function to use for interpolation.
 *
 * Returns: The ID of the task.
 *
 * Example:
 * ---
 * scheduleInterpolateTask!q{position}( transform, startNode, endNode, 100.msecs );
 * ---
 */
UUID scheduleInterpolateTask( string prop, T, Owner )( ref Owner own, T start, T end, Duration duration, T function( T, T, float ) interpFunc = &lerp!( T ) )
    if( __traits( compiles, mixin( "own." ~ prop ) ) )
{
    auto startTime = Time.totalTime;
    return scheduleTimedTask( duration, ( elapsed )
    {
        mixin( "own." ~ prop ~ " = interpFunc( start, end, elapsed / duration.toSeconds );" );
    } );
}
///
unittest
{
    import std.stdio;

    writeln( "Dash Tasks scheduleInterpolateTask unittest 2" );

    auto testClass = new TestPropertyInterpolate;
    testClass.vector = vec3f( 0, 0, 0 );
    vec3f start = vec3f( 0, 1, 0 );
    vec3f end = vec3f( 0, 1, 1 );
    scheduleInterpolateTask!q{vector}( testClass, start, end, 100.msecs );

    while( scheduledTasks.length )
    {
        executeTasks();
        Time.update();
    }

    assert( testClass.vector == end );
}
version( unittest )
class TestPropertyInterpolate
{
    import dash.utility.math;

    private vec3f _vector;
    public @property vec3f vector() { return _vector; }
    public @property void vector( vec3f newVal ) { _vector = newVal; }
}

/**
 * Schedule a task to be executed until the duration expires.
 *
 * Params:
 *  duration =          The duration to execute the task for.
 *  dg =                The task to execute.
 *
 * Returns: The ID of the task.
 */
UUID scheduleTimedTask( Duration duration, void delegate() dg )
{
    auto startTime = Time.totalTime;
    return scheduleTask( {
        dg();
        return Time.totalTime >= startTime + duration.toSeconds;
    } );
}

/// ditto
UUID scheduleTimedTask( Duration duration, void delegate( float ) dg )
{
    auto startTime = Time.totalTime;
    return scheduleTask( {
        dg( min( Time.totalTime - startTime, duration.toSeconds ) );
        return Time.totalTime >= startTime + duration.toSeconds;
    } );
}

/// ditto
UUID scheduleTimedTask( Duration duration, void delegate( float, float ) dg )
{
    auto startTime = Time.totalTime;
    return scheduleTask( {
        dg( min( Time.totalTime - startTime, duration.toSeconds ), duration.toSeconds );
        return Time.totalTime >= startTime + duration.toSeconds;
    } );
}

/// ditto
UUID scheduleTimedTask( Duration duration, bool delegate() dg )
{
    auto startTime = Time.totalTime;
    return scheduleTask( {
        if( dg() )
            return true;
        else
            return Time.totalTime >= startTime + duration.toSeconds;
    } );
}

/// ditto
UUID scheduleTimedTask( Duration duration, bool delegate( float ) dg )
{
    auto startTime = Time.totalTime;
    return scheduleTask( {
        if( dg( min( Time.totalTime - startTime, duration.toSeconds ) ) )
            return true;
        else
            return Time.totalTime >= startTime + duration.toSeconds;
    } );
}

/// ditto
UUID scheduleTimedTask( Duration duration, bool delegate( float, float ) dg )
{
    auto startTime = Time.totalTime;
    return scheduleTask( {
        if( dg( min( Time.totalTime - startTime, duration.toSeconds ), duration.toSeconds ) )
            return true;
        else
            return Time.totalTime >= startTime + duration.toSeconds;
    } );
}

/**
 * Schedule a task to be execuated after the specified amount of time.
 *
 * Params:
 *  delay =             The ammount of time to wait before executing.
 *  dg =                The task to execute.
 *
 * Returns: The ID of the task.
 */
UUID scheduleDelayedTask( Duration delay, void delegate() dg )
{
    auto startTime = Time.totalTime;
    return scheduleTask( {
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
///
unittest
{
    bool taskRan = false;

    scheduleDelayedTask( 1.seconds, { taskRan = true; } );

    while( scheduledTasks.length )
    {
        executeTasks();
        Time.update();
    }

    assert( taskRan );
}

/**
 * Schedule a task to be executed on an interval, until the task returns true.
 *
 * Params:
 *  interval =          The interval on which to call this task.
 *  dg =                The task to execute.
 *
 * Returns: The ID of the task.
 */
UUID scheduleIntervaledTask( Duration interval, bool delegate() dg )
{
    auto timeTilExe = interval.toSeconds;
    return scheduleTask( {
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
 *
 * Returns: The ID of the task.
 */
UUID scheduleIntervaledTask( Duration interval, uint numExecutions, void delegate() dg )
{
    auto timeTilExe = interval.toSeconds;
    uint executedTimes = 0;
    return scheduleTask( {
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
 *
 * Returns: The ID of the task.
 */
UUID scheduleIntervaledTask( Duration interval, uint numExecutions, bool delegate() dg )
{
    auto timeTilExe = interval.toSeconds;
    uint executedTimes = 0;
    return scheduleTask( {
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
    size_t[] toRemove;
    foreach( i, task; scheduledTasks/*.parallel*/ )
    {
        if( task[ 0 ]() )
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
 * Cancels the given task from executing.
 *
 * Params:
 *  id =				The id of the task to cancel.
 */
void cancelTask( UUID id )
{
    import std.algorithm;

    auto i = scheduledTasks.countUntil!( tup => tup[ 1 ] == id );

    // Get tasks after one being removed.s
    auto end = scheduledTasks[ i+1..$ ];
    // Get tasks before one being removed.
    scheduledTasks = scheduledTasks[ 0..i ];
    // Add end back.
    scheduledTasks ~= end;
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
Tuple!( bool delegate(), UUID )[] scheduledTasks;
