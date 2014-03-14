module StrLib;

enum MAX_STRINGS = 256;
enum MAX_LENGTH  = 64;

import std.string;

__gshared void*[string] szStrings;
__gshared string[] sortestrings;

export void AddString(string pStringIn)
{
    if (pStringIn !in szStrings)
        szStrings[pStringIn] = null;
}

export void DeleteString(string pStringIn)
{
    if (pStringIn in szStrings)
        szStrings.remove(pStringIn);
}

export string[] GetStrings()
{
    sortestrings = szStrings.keys;
    sortestrings.sort;
    return sortestrings;
}
