/**
 * Defines methods for scheduling tasks with different conditions for executing.
 *
 */
module utility.tasks;
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

void resetTasks()
{
    scheduledTasks = [];
}

private:
/// The tasks that have been scheduled
bool delegate()[] scheduledTasks;
