module utility.filepath;
static import std.file, std.path;

class FilePath
{
public:
	enum Resources : string
	{
		Meshes = "./Game/Meshes",
		Textures = "./Game/Textures",
		Scripts = "./Game/Scripts",
		Prefabs = "./Game/Prefabs",
		Objects = "./Game/Objects",
		Shaders = "./Game/Shaders",
		UI = "./Game/UI",
		Config = "./Game/Config.yaml"
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
		if( std.path.isValidPath( path ) )
			_fullPath = std.path.buildNormalizedPath( std.path.absolutePath( path ) );
	}

private:
	string _fullPath;
}
