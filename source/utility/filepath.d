module utility.filepath;
static import std.file, std.path;

class FilePath
{
public:
	enum ResourceHome = "./Game";

	enum Resources : string
	{
		Meshes = ResourceHome ~ "/Meshes",
		Textures = ResourceHome ~ "/Textures",
		Scripts = ResourceHome ~ "/Scripts",
		Prefabs = ResourceHome ~ "/Prefabs",
		Objects = ResourceHome ~ "/Objects",
		Shaders = ResourceHome ~ "/Shaders",
		UI = ResourceHome ~ "/UI",
		Config = ResourceHome ~ "/Config.yaml"
	}

	static FilePath[] scanDirectory( string path, string pattern = "" )
	{
		// Get absolute path to folder
		string safePath = std.path.buildNormalizedPath( std.path.absolutePath( path ) );

		// Start array
		auto files = new FilePath[ 1 ];
		uint filesFound = 0;

		// Add file to array
		void handleFile( string name )
		{
			if( filesFound == files.length )
				files.length *= 2;

			files[ filesFound++ ] = new FilePath( name );
		}

		// Find files
		if( pattern.length )
			foreach( name; std.file.dirEntries( safePath, pattern, std.file.SpanMode.breadth ) )
				handleFile( name );
		else
			foreach( name; std.file.dirEntries( safePath, std.file.SpanMode.breadth ) )
				handleFile( name );

		files.length = filesFound;

		return files;
	}

	@property string fullPath()		{ return _fullPath; }
	@property string relativePath()	{ return std.path.relativePath( fullPath ); }
	@property string fileName()		{ return std.path.baseName( fullPath ); }
	@property string baseFileName()	{ return std.path.stripExtension( fileName ); }
	@property string directory()	{ return std.path.dirName( fullPath ); }
	@property string extension()	{ return std.path.extension( fullPath ); }

	this( string path )
	{
		if( std.file.isFile( path ) )
			_fullPath = std.path.buildNormalizedPath( std.path.absolutePath( path ) );
		else
			throw new Exception( "Invalid file name." );
	}

private:
	string _fullPath;
}
