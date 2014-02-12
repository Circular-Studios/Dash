/**
 * Defines the static Assets class, a static class which manages all textures, meshes, etc...
 */
module components.assets;
import components;
import utility.filepath;

import derelict.freeimage.freeimage;

static class Assets
{
static:
public:
	/**
	 * Get the asset with the given type and name.
	 */
	T get( T )( string name ) if( is( T : Component ) )
	{
		return cast(T)componentShelf[ name ];
	}

	/**
	 * Load all assets in the FilePath.ResourceHome folder.
	 */
	void initialize()
	{
		DerelictFI.load();

		foreach( file; FilePath.scanDirectory( FilePath.Resources.Meshes ) )
		{
			componentShelf[ file.baseFileName ] = new Mesh( file.fullPath );
		}

		foreach( file; FilePath.scanDirectory( FilePath.Resources.Textures ) )
		{
			componentShelf[ file.baseFileName ] = new Texture( file.fullPath );
		}

		componentShelf.rehash();
	}

	/**
	 * Unload and destroy all stored assets.
	 */
	void shutdown()
	{
		foreach_reverse( index; 0 .. componentShelf.length )
		{
			auto name = componentShelf.keys[ index ];
			componentShelf[ name ].shutdown();
			componentShelf.remove( name );
		}
		/*foreach( name, asset; componentShelf )
		{
			asset.shutdown();
			componentShelf.remove( name );
		}*/
	}

private:
	Component[string] componentShelf;
}
