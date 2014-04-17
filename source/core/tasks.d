/**
 * Defines methods for scheduling tasks with different conditions for executing.
 *
 */
module core.tasks;
import utility.time;

import core.time;

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
 * Schedule a task to be executed until the duration expires.
 *
 * Params:
 *  dg =                The task to execute
 *  duration =          The duration to execute the task for
 */
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
 *  dg =                The task to execute
 *  delay =             The ammount of time to wait before executing
 */
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

private:
/// The tasks that have been scheduled
bool delegate()[] scheduledTasks;
