/**
 * Defines methods for scheduling tasks with different conditions for executing.
 *
 */
module utility.tasks;
import utility.time;

import gl3n.util: is_vector, is_matrix, is_quaternion;
import gl3n.interpolate: lerp;

import core.time;
import std.algorithm: min;

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
void scheduleInterpolateTask(T)( ref T val, T start, T end, Duration duration, T function( T, T, float ) interpFunc = &lerp!T ) if( is_vector!T || is_matrix!T || is_quaternion!T )
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

    writeln( "Dash tasks scheduleInterpolateTask unittest" );

    shared vec3 interpVec = shared vec3( 0, 0, 0 );
    shared vec3 start = shared vec3( 0, 1, 0 );
    shared vec3 end = shared vec3( 0, 1, 1 );

    scheduleInterpolateTask( interpVec, start, end, 100.msecs );

    while( scheduledTasks.length )
        executeTasks();

    assert( interpVec == end );
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
 * Executes all scheduled tasks.
 */
void executeTasks()
{
    size_t[] toRemove;    // Indicies of tasks which are done
    foreach( i, task; scheduledTasks )
    {
        if( task() )
            toRemove ~= i;
    }
    foreach( i; toRemove )
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
