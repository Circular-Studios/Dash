module utility.file;
static import std.file, std.path;
import std.stdio;

class File
{
public:
static
{
	File[] scanDirectory( string path, string pattern = "*" )
	{
		File[] files;

		foreach( name; std.file.dirEntries( path, pattern, std.file.SpanMode.breadth ) )
		{
			writeln( ( new File( name ) ).fullPath );
		}

		return files;
	}
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
