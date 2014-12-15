/**
 * TODO
 */
module dash.utility.resources;
import dash.utility.output;

import std.file, std.path, std.stdio, std.array, std.algorithm, std.datetime;

/**
 * Paths to the different resource files.
 */
enum Resources : string
{
    Home = "..",
    Animation = Home ~ "/Animation",
    Materials = Home ~ "/Materials",
    Meshes = Home ~ "/Meshes",
    Textures = Home ~ "/Textures",
    Audio = Home ~ "/Audio",
    Scripts = Home ~ "/Scripts",
    Prefabs = Home ~ "/Prefabs",
    Objects = Home ~ "/Objects",
    Shaders = Home ~ "/Shaders",
    UI = Home ~ "/UI",
    ConfigDir = Home ~ "/Config",
    ConfigFile = ConfigDir ~ "/Config",
    InputBindings = ConfigDir ~ "/Input",
}

/**
 * Get all files in a given directory.
 */
Resource[] scanDirectory( string path, string pattern = "" )
{
    // Get absolute path to folder
    string safePath = path.absolutePath().buildNormalizedPath();

    if( !safePath.exists() )
    {
        tracef( "%s does not exist.", path );
        return [];
    }

    // Start array
    return ( pattern.length
                ? safePath.dirEntries( pattern, SpanMode.breadth ).array
                : safePath.dirEntries( SpanMode.breadth ).array )
            .filter!( entry => entry.isFile )
            .map!( entry => Resource( entry ) )
            .array();
}

enum internalResource = Resource( true );

/**
 * Represents a resource on the file system.
 */
struct Resource
{
public:
    @disable this();
    
    /**
     * Creates a Resource from the given filepath.
     *
     * Params:
     *  filePath =          The path of the file created.
     */
    this( string filePath )
    {
        assert( filePath.isFile(), "Invalid file name." );
        _fullPath = filePath.absolutePath().buildNormalizedPath();
    }

    /**
     * Shuts down the File if it was instantiated.
     */
    ~this()
    {
        if( file && file.isOpen )
            file.close();
    }

    /// The full path to the file.
    @property string fullPath()         { return _fullPath; }
    /// The relative path from the executable to the file.
    @property string relativePath()     { return _fullPath.relativePath(); }
    /// The name of the file with its extension.
    @property string fileName()         { return _fullPath.baseName(); }
    /// The name of the file without its extension.
    @property string baseFileName()     { return fileName().stripExtension(); }
    /// The path to the directory containing the file.
    @property string directory()        { return _fullPath.dirName(); }
    /// The extensino of the file.
    @property string extension()        { return _fullPath.extension(); }
    /// Checks if the file still exists.
    bool exists() @property             { return isInternal || fullPath.isFile(); }
    /// Converts to a std.stdio.File
    File* getFile( string mode = "r" )
    {
        if( isInternal )
            return null;

        if( !file )
            file = new File( _fullPath, mode );

        return file;
    }

    /**
     * Read the contents of the file.
     *
     * Returns: The contents of a file as a ubyte[].
     */
    ubyte[] read()
    {
        if( isInternal )
            return [];

        markRead();
        return cast(ubyte[])_fullPath.read();
    }

    /**
     * Read the contents of the file.
     *
     * Returns: The contents of a file as a string.
     */
    string readText()
    {
        if( isInternal )
            return "";

        markRead();
        return _fullPath.readText();
    }

    /**
     * Checks if the file has been modified since it was last loaded.
     *
     * Returns: Whether the last modified time is more recent than the time it was last read.
     */
    bool needsRefresh()
    {
        if( isInternal )
            return false;

        return fullPath.timeLastModified > timeRead;
    }

private:
    string _fullPath;
    bool isInternal;
    std.stdio.File* file;
    SysTime timeRead;

    this( bool internal )
    {
        isInternal = internal;
        _fullPath = "__internal";
    }

    void markRead()
    {
        if( !isInternal )
            timeRead = fullPath.timeLastModified();
    }
}
