module components.assets;
import components.icomponent, components.mesh, components.texture;
import utility.filepath;

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
		foreach( file; FilePath.scanDirectory( FilePath.Resources.Meshes ) )
		{
			componentShelf[ file.baseFileName ] = new Mesh( file.fullPath );
		}

		foreach( file; FilePath.scanDirectory( FilePath.Resources.Textures ) )
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
