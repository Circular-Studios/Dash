/**
 * Defines the static Assets class, a static class which manages all textures, meshes, etc...
 */
module components.assets;
import components;
import utility.filepath, utility.config;

import yaml;
import derelict.freeimage.freeimage;

final abstract class Assets
{
public static:
	/**
	 * Get the asset with the given type and name.
	 */
	final T get( T )( string name ) if( is( T == Mesh ) || is( T == Texture ) || is( T == Material ) )
	{
		static if( is( T == Mesh ) )
		{
			return meshes[ name ];
		}
		else static if( is( T == Texture ) )
		{
			return textures[ name ];
		}
		else static if( is( T == Material ) )
		{
			return materials[ name ];
		}
		else static assert( false, "Material of type " ~ T.stringof ~ " is not maintained by Assets." );
	}

	/**
	 * Load all assets in the FilePath.ResourceHome folder.
	 */
	final void initialize()
	{
		DerelictFI.load();

		foreach( file; FilePath.scanDirectory( FilePath.Resources.Meshes ) )
		{
			meshes[ file.baseFileName ] = new Mesh( file.fullPath );
		}

		foreach( file; FilePath.scanDirectory( FilePath.Resources.Textures ) )
		{
			textures[ file.baseFileName ] = new Texture( file.fullPath );
		}

		Config.processYamlDirectory(
			FilePath.Resources.Materials,
			( Node object )
			{
				auto name = object[ "Name" ].as!string;

				materials[ name ] = Material.createFromYaml( object );
			} );

		meshes.rehash();
		textures.rehash();
		materials.rehash();
	}

	/**
	 * Unload and destroy all stored assets.
	 */
	final void shutdown()
	{
		foreach_reverse( index; 0 .. meshes.length )
		{
			auto name = meshes.keys[ index ];
			meshes[ name ].shutdown();
			meshes.remove( name );
		}
		foreach_reverse( index; 0 .. textures.length )
		{
			auto name = textures.keys[ index ];
			textures[ name ].shutdown();
			textures.remove( name );
		}
		foreach_reverse( index; 0 .. materials.length )
		{
			auto name = materials.keys[ index ];
			materials[ name ].shutdown();
			materials.remove( name );
		}
	}

private:
	Mesh[string] meshes;
	Texture[string] textures;
	Material[string] materials;
}
