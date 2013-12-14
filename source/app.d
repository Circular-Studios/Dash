//*
import core.dgame;

void main()
{
    ( new DGame() ).run();
}
/*/
import std.stdio;
import yaml;

void main()
{
    //Read the input.
    Node root = Loader("Test.yaml").load();

    //Display the data read.
    foreach(string word; root["HelloWorld"])
    {
        writeln(word);
    }
    writeln("The answer is ", root["Answer"].as!int);

    //Dump the loaded document to output.yaml.
    Dumper("output.yaml").dump(root);
}
//*/