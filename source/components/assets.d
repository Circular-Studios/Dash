/**
 * Defines the static Assets class, a static class which manages all textures, meshes, materials, and animations.
 */
module components.assets;
import components, utility;

import std.string, std.array;

import yaml;
import derelict.freeimage.freeimage, derelict.assimp3.assimp;
shared AssetManager Assets;

shared static this()
{
    Assets = new shared AssetManager;
}

/**
 * Assets manages all assets that aren't code, GameObjects, or Prefabs.
 */
shared final class AssetManager
{
private:
    Mesh[string] meshes;
    Texture[string] textures;
    Material[string] materials;
    AssetAnimation[string] animations;

public:
    /// TODO
    Mesh unitSquare;

    /**
     * Get the asset with the given type and name.
     */
    final shared(T) get( T )( string name ) if( is( T == Mesh ) || is( T == Texture ) || is( T == Material ) || is( T == AssetAnimation ))
    {
        enum get( string array ) = q{
            if( auto result = name in $array )
            {
                return *result;
            }
            else
            {
                logFatal( "Unable to find ", name, " in $array." );
                return null;
            }
        }.replace( "$array", array );
        static if( is( T == Mesh ) )
        {
            mixin( get!q{meshes} );
        }
        else static if( is( T == Texture ) )
        {
            mixin( get!q{textures} );
        }
        else static if( is( T == Material ) )
        {
            mixin( get!q{materials} );
        }
        else static if( is( T == AssetAnimation ) )
        {
            mixin( get!q{animations} );
        }
        else static assert( false, "Material of type " ~ T.stringof ~ " is not maintained by Assets." );
    }

    /**
     * Load all assets in the FilePath.ResourceHome folder.
     */
    final void initialize()
    {
        DerelictFI.load();

        // Initial assimp start
        DerelictASSIMP3.load();

        // Make sure fbxs are supported.
        assert(aiIsExtensionSupported(".fbx".toStringz), "fbx format isn't supported by assimp instance!");

        // Load the unitSquare
        unitSquare = new shared Mesh( "", aiImportFileFromMemory(unitSquareMesh.toStringz, unitSquareMesh.length,
                                                aiProcess_CalcTangentSpace | aiProcess_Triangulate | 
                                                aiProcess_JoinIdenticalVertices | aiProcess_SortByPType,
                                                "obj" ).mMeshes[0] );

        foreach( file; FilePath.scanDirectory( FilePath.Resources.Meshes ) )
        {
            // Load mesh
            const aiScene* scene = aiImportFile( file.fullPath.toStringz,
                                                aiProcess_CalcTangentSpace | aiProcess_Triangulate | 
                                                aiProcess_JoinIdenticalVertices | aiProcess_SortByPType );
                                                //| aiProcess_FlipWindingOrder );
            assert(scene, "Failed to load scene file '" ~ file.fullPath ~ "' Error: " ~ aiGetErrorString().fromStringz);
            
            // If animation data, add animation
            if( file.baseFileName in meshes )
                logWarning( "Mesh ", file.baseFileName, " exsists more than once." );

            // Add mesh
            if( scene.mNumMeshes > 0 )
            {
                if( scene.mNumAnimations > 0 )
                    animations[ file.baseFileName ] = new shared AssetAnimation( scene.mAnimations[ 0 ], scene.mMeshes[ 0 ], scene.mRootNode );

                meshes[ file.baseFileName ] = new shared Mesh( file.fullPath, scene.mMeshes[ 0 ] );
            }
            else
            {
                logWarning( "Assimp did not contain mesh data, ensure you are loading a valid mesh." );
            }

            // Release mesh
            aiReleaseImport( scene );
        }

        foreach( file; FilePath.scanDirectory( FilePath.Resources.Textures ) )
        {
            if( file.baseFileName in textures )
               logWarning( "Texture ", file.baseFileName, " exists more than once." );

            textures[ file.baseFileName ] = new shared Texture( file.fullPath );
        }

        foreach( object; loadYamlDocuments( FilePath.Resources.Materials ) )
        {
            auto name = object[ "Name" ].as!string;

            if( name in materials )
                logWarning( "Material ", name, " exists more than once." );
            
            materials[ name ] = Material.createFromYaml( object );
        }

        meshes.rehash();
        textures.rehash();
        materials.rehash();
        animations.rehash();
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
            materials.remove( name );
        }
        foreach_reverse( index; 0 .. animations.length )
        {
            auto name = animations.keys[ index ];
            animations[ name ].shutdown();
            animations.remove( name );
        }
    }
}

/// TODO
immutable string unitSquareMesh = q{
v -1.0 1.0 0.0
v -1.0 -1.0 0.0
v 1.0 1.0 0.0
v 1.0 -1.0 0.0

vt 0.0 0.0
vt 0.0 1.0
vt 1.0 0.0
vt 1.0 1.0

vn 0.0 0.0 1.0

f 4/3/1 3/4/1 1/2/1
f 2/1/1 4/3/1 1/2/1
};
