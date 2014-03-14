module addUtf;

// hackish script to swap toUTF16z with forwarding function

import std.algorithm;
import std.string;
import std.array;
import std.stdio;
import std.file;
import std.path;

auto quote = "
auto toUTF16z(S)(S s)
{
    return toUTFz!(const(wchar)*)(s);
}
";

void main()
{
    foreach (string entry; dirEntries(rel2abs(curdir), SpanMode.depth))
    {
        if (entry.isFile && entry.getExt == "d")
        {
            process(entry);
        }
    }
}

void process(string filename)
{
    string text;
	auto file = File(filename, "r");
    int found;

    foreach (line; file.byLine)
    {
        if (found == 1)
        {
            text ~= quote;
            found += 1;
        }
        
        
        if (line.startsWith("import std.utf"))
        {
            found++;
            
            if (line.countUntil(", toUTF16z;"))
            {
                line = line.replace(", toUTF16z;", ", toUTFz;");
            }
            
            //~ , toUTF16z
        }
        
        text ~= line ~ "\n";
    }
    
    file.close();
    file = File(filename, "w");
    file.write(text);
}
