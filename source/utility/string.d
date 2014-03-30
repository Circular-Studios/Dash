/**
*   Defines utility functions for strings
*/
module utility.string;

import std.array;

/// fromStringz
/**
*   Returns new string formed from C-style (null-terminated) string $(D msg). Usefull
*   when interfacing with C libraries. For D-style to C-style convertion use std.string.toStringz.
*   
*   Authors: NCrashed
*/
string fromStringz(const char* msg) nothrow
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
