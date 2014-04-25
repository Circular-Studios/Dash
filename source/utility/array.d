module utility.array;

/**
 * Removes an element from a shared array.
 *
 * Params:
 *  haystack =          The array to remove from.
 *  needle =            The element to remove.
 *
 * Returns: A copy of haystack without needle in it.
 */
shared(T[]) remove(T)( shared T[] haystack, shared T needle )
{
    import std.algorithm, core.memory;
    // Get index of object being removed
    auto needleIndex = (cast(T[])haystack).countUntil( cast(T)needle );

    // Return if not actually a child
    if( needleIndex == -1 )
        return haystack;

    auto result = cast(shared T*)GC.malloc( T.sizeof * ( haystack.length - 1 ) );

    // Add beginning of list
    result[ 0..needleIndex ] = haystack[ 0..needleIndex ];
    // Add end of list
    result[ needleIndex..haystack.length - 1 ] = haystack[ needleIndex+1..$ ];

    return result[ 0..haystack.length - 1 ];
}
