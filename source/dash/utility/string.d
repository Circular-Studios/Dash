/**
*   Defines utility functions for strings
*/
module dash.utility.string;

import std.array, std.traits;

// std.string.fromStringz was introduced in https://github.com/D-Programming-Language/phobos/pull/1607
static if( __VERSION__ < 2066 )
{
    /**
     * Returns new string formed from C-style (null-terminated) string $(D msg). Usefull
     * when interfacing with C libraries. For D-style to C-style convertion use std.string.toStringz.
     *
     * Params:
     *  msg =                 The C string to convert.
     *
     * Authors: NCrashed
     */
    string fromStringz( const char* msg ) pure nothrow
    {
        scope(failure) return "";
        if( msg is null ) return "";

        auto buff = appender!(char[]);
        uint i = 0;
        while( msg[i] != cast(char)0 )
        {
            buff.put(msg[i++]);
        }

        return buff.data.idup;
    }
    /// Example
    unittest
    {
        char[] cstring = "some string".dup ~ cast(char)0;

        assert(cstring.ptr.fromStringz == "some string");
        assert(null.fromStringz == "");
    }
}

/**
 * Replaces each key in replaceMap with it's value.
 *
 * Params:
 *  base =              The string to replace on.
 *  replaceMap =        The map to use to replace things.
 *
 * Returns: The updated string.
 */
T replaceMap( T, TKey, TValue )( T base, TKey[TValue] replaceMap )
    if( isSomeString!T && isSomeString!TKey && isSomeString!TValue )
{
    scope(failure) return "";
    if( base is null ) return "";

    auto result = base;

    foreach( key, value; replaceMap )
    {
        result = result.replace( key, value );
    }

    return result;
}
/// Example
unittest
{
    assert( "$val1 $val2 val3".replaceMap( [ "$val1": "test1", "$val2": "test2", "$val3": "test3" ] ) == "test1 test2 val3" );
}
