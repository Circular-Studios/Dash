/**
 * Defines the FilePath class, which stores default resource paths, and handles path manipulation.
 */
module dash.utility.filepath;
import dash.utility.output;

static import std.file, std.path;
import std.stdio, std.array;

deprecated( "Use utility.filesystem instead." ):

/**
 * A class which stores default resource paths, and handles path manipulation.
 */
final class FilePath
{
private:
    string _fullPath;
    string _relativePath;
    string _fileName;
    string _baseFileName;
    string _directory;
    string _extension;
    File* file;

public:
    /**
     * The path to the resources home folder.
     */
    enum ResourceHome = "..";

    /**
     * Paths to the different resource files.
     */
    enum Resources : string
    {
        Materials = ResourceHome ~ "/Materials",
        Meshes = ResourceHome ~ "/Meshes",
        Textures = ResourceHome ~ "/Textures",
        Scripts = ResourceHome ~ "/Scripts",
        Prefabs = ResourceHome ~ "/Prefabs",
        Objects = ResourceHome ~ "/Objects",
        Shaders = ResourceHome ~ "/Shaders",
        UI = ResourceHome ~ "/UI",
        ConfigDir = ResourceHome ~ "/Config",
        ConfigFile = ConfigDir ~ "/Config",
        InputBindings = ConfigDir ~ "/Input",
        CompactContentFile = ResourceHome ~ "/Content",
    }

    /**
     * Get all files in a given directory.
     */
    final static FilePath[] scanDirectory( string path, string pattern = "" )
    {
        // Get absolute path to folder
        string safePath = std.path.buildNormalizedPath( std.path.absolutePath( path ) );

        if( !std.file.exists( safePath ) )
        {
            logDebug( path, " does not exist." );
            return [];
        }

        // Start array
        FilePath[] files;

        auto dirs = pattern.length
                    ? std.file.dirEntries( safePath, pattern, std.file.SpanMode.breadth ).array
                    : std.file.dirEntries( safePath, std.file.SpanMode.breadth ).array;

        // Find files
        foreach( entry; dirs )
            if( entry.isFile )
                files ~= new FilePath( entry.name );

        return files;
    }

    /// The full path to the file.
    final @property string fullPath()       { return _fullPath; }
    /// The relative path from the executable to the file.
    final @property string relativePath()
    {
        if( !_relativePath )
            _relativePath = std.path.relativePath( _fullPath );

        return _relativePath;
    }
    /// The name of the file with its extension.
    final @property string fileName()
    {
        if( !_fileName )
            _fileName = std.path.baseName( _fullPath );

        return _fileName;
    }
    /// The name of the file without its extension.
    final @property string baseFileName()
    {
        if( !_baseFileName )
            _baseFileName = std.path.stripExtension( fileName );

        return _baseFileName;
    }
    /// The path to the directory containing the file.
    final @property string directory()
    {
        if( !_directory )
            _directory = std.path.dirName( _fullPath );

        return _directory;
    }
    /// The extensino of the file.
    final @property ref string extension()
    {
        if( !_extension )
            _extension = std.path.extension( _fullPath );

        return _extension;
    }
    /// Converts to a std.stdio.File
    final File* toFile( string mode = "r" )
    {
        if( !file )
            file = new File( _fullPath, mode );

        return file;
    }

    /**
     * Read the contents of the file.
     *
     * Returns: The contents of a file as a string.
     */
    final string getContents()
    {
        return cast(string)std.file.read(_fullPath);
    }

    /**
     * Create an instance based on a given file path.
     *
     * Params:
     *  path =            The path of the file created.
     */
    this( string path )
    {
        // Don't check validity during tests.
        version( unittest ) { }
        else if( !std.file.isFile( path ) )
        {
            throw new Exception( "Invalid file name." );
        }

        _fullPath = std.path.buildNormalizedPath( std.path.absolutePath( path ) );
    }

    /**
     * Shuts down the File if it was instantiated.
     */
    ~this()
    {
        if( file && file.isOpen )
            file.close();
    }
}
unittest
{
    import std.stdio;
    writeln( "Dash FilePath properties unittest" );

    auto fp = new FilePath( "../Config/Config.yml" );

    assert( fp.fileName == "Config.yml", "FilePath.fileName error." );
    assert( fp.baseFileName == "Config", "FilePath.baseFileName error." );
    assert( fp.extension == ".yml", "FilePath.extension error." );
}
