module components.assets;
import components.icomponent, components.mesh, components.texture;
import utility.file;

static class Assets
{
static:
public:
	T getAsset( T )( string name )
	{
		return cast(T)componentShelf[ name ];
	}

	void initialize()
	{
		foreach( file; File.scanDirectory( File.Resources.Meshes ) )
		{
			componentShelf[ file.baseFileName ] = new Mesh( file.fullPath );
		}

		foreach( file; File.scanDirectory( File.Resources.Textures ) )
		{
			componentShelf[ file.baseFileName ] = new Texture( file.fullPath );
		}
	}

	void shutdown()
	{
		foreach( key; componentShelf.keys )
		{
			componentShelf.remove( key );
		}
	}

private:
	IComponent[string] componentShelf;
}
