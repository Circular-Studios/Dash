/**
 * TODO
 */
module utility.resources;
import utility;

import std.file, std.path, std.stdio, std.array, std.datetime;

/**
 * Paths to the different resource files.
 */
enum Resources : string
{
    Home = "..",
    Materials = Home ~ "/Materials",
    Meshes = Home ~ "/Meshes",
    Textures = Home ~ "/Textures",
    Scripts = Home ~ "/Scripts",
    Prefabs = Home ~ "/Prefabs",
    Objects = Home ~ "/Objects",
    Shaders = Home ~ "/Shaders",
    UI = Home ~ "/UI",
    ConfigDir = Home ~ "/Config",
    ConfigFile = ConfigDir ~ "/Config",
    InputBindings = ConfigDir ~ "/Input",
    CompactContentFile = Home ~ "/Content",
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
        logDebug( path, " does not exist." );
        return [];
    }

    // Start array
    Resource[] files;

    auto dirs = pattern.length
                ? safePath.dirEntries( pattern, SpanMode.breadth ).array
                : safePath.dirEntries( SpanMode.breadth ).array;

    // Find files
    foreach( entry; dirs )
        if( entry.isFile )
            files ~= Resource( entry.name );

    return files;
}

struct Resource
{
public:
    /**
     * Creates a Resource from the given filepath.
     *
     * Params:
     *  filePath =          The path of the file created.
     */
    this( string filePath )
    {
        if( filePath.isFile() )
            _fullPath = filePath.absolutePath().buildNormalizedPath();
        else
            throw new Exception( "Invalid file name." );

        markRead();
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
    @property string fullPath()       { return _fullPath; }
    /// The relative path from the executable to the file.
    @property string relativePath()
    {
        if( !_relativePath )
            _relativePath = _fullPath.relativePath();

        return _relativePath;
    }
    /// The name of the file with its extension.
    @property string fileName()
    {
        if( !_fileName )
            _fileName = _fullPath.baseName();

        return _fileName;
    }
    /// The name of the file without its extension.
    @property string baseFileName()
    {
        if( !_baseFileName )
            _baseFileName = fileName.stripExtension();

        return _baseFileName;
    }
    /// The path to the directory containing the file.
    @property string directory()
    {
        if( !_directory )
            _directory = _fullPath.dirName();

        return _directory;
    }
    /// The extensino of the file.
    @property ref string extension()
    {
        if( !_extension )
            _extension = _fullPath.extension(  );

        return _extension;
    }
    /// Converts to a std.stdio.File
    File* getFile( string mode = "r" )
    {
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
        return fullPath.timeLastModified > timeRead;
    }

private:
    string _fullPath;
    string _relativePath;
    string _fileName;
    string _baseFileName;
    string _directory;
    string _extension;
    std.stdio.File* file;
    SysTime timeRead;

    void markRead()
    {
        timeRead = fullPath.timeLastModified();
    }
}
