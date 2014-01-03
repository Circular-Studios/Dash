/**
 * Defines the static Assets class, a static class which manages all textures, meshes, etc...
 */
module components.assets;
import components.icomponent, components.mesh, components.texture;
import utility.filepath;

import derelict.freeimage.freeimage;

static class Assets
{
static:
public:
	/**
	 * Get the asset with the given type and name.
	 */
	T getAsset( T )( string name )
	{
		return cast(T)componentShelf[ name ];
	}

	/**
	 * Load all assets in the FilePath.ResourceHome folder.
	 */
	void initialize()
	{
		DerelictFI.load( "bin/FreeImage.dll" );

		foreach( file; FilePath.scanDirectory( FilePath.Resources.Meshes ) )
		{
			componentShelf[ file.baseFileName ] = new Mesh( file.fullPath );
		}

		foreach( file; FilePath.scanDirectory( FilePath.Resources.Textures ) )
		{
			componentShelf[ file.baseFileName ] = new Texture( file.fullPath );
		}
	}

	/**
	 * Unload and destroy all stored assets.
	 */
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
