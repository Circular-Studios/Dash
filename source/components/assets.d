/**
 * Defines the static Assets class, a static class which manages all textures, meshes, materials, and animations.
 */
module components.assets;
import components, utility;

import std.string, std.array;

import yaml;
import derelict.freeimage.freeimage, derelict.assimp3.assimp;
AssetManager Assets;

static this()
{
    Assets = new AssetManager;
}

/**
 * Assets manages all assets that aren't code, GameObjects, or Prefabs.
 */
final class AssetManager
{
private:
    Mesh[string] meshes;
    Texture[string] textures;
    Material[string] materials;
    AssetAnimation[string] animations;

public:
    /// Basic quad, generally used for billboarding.
    Mesh unitSquare;

    /**
     * Get the asset with the given type and name.
     */
    final T get( T )( string name ) if( is( T == Mesh ) || is( T == Texture ) || is( T == Material ) || is( T == AssetAnimation ))
    {
        enum get( Type, string array ) = q{
            static if( is( T == $Type ) )
            {
                if( auto result = name in $array )
                {
                    result.isUsed = true;
                    return *result;
                }
                else
                {
                    logFatal( "Unable to find ", name, " in $array." );
                    return null;
                }
            }
        }.replaceMap( [ "$array": array, "$Type": Type.stringof ] );

        mixin( get!( Mesh, q{meshes} ) );
        mixin( get!( Texture, q{textures} ) );
        mixin( get!( Material, q{materials} ) );
        mixin( get!( AssetAnimation, q{animations} ) );
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
        unitSquare = new Mesh( "", aiImportFileFromMemory(
                                        unitSquareMesh.toStringz, unitSquareMesh.length,
                                        aiProcess_CalcTangentSpace | aiProcess_Triangulate | 
                                        aiProcess_JoinIdenticalVertices | aiProcess_SortByPType,
                                        "obj" ).mMeshes[0] );

        foreach( file; FilePath.scanDirectory( FilePath.Resources.Meshes ) )
        {
            // Load mesh
            const aiScene* scene = aiImportFile( file.fullPath.toStringz,
                                                 aiProcess_CalcTangentSpace | aiProcess_Triangulate | 
                                                 aiProcess_JoinIdenticalVertices | aiProcess_SortByPType );
            assert( scene, "Failed to load scene file '" ~ file.fullPath ~ "' Error: " ~ aiGetErrorString().fromStringz );
            
            // If animation data, add animation
            if( file.baseFileName in meshes )
                logWarning( "Mesh ", file.baseFileName, " exsists more than once." );

            // Add mesh
            if( scene.mNumMeshes > 0 )
            {
                if( scene.mNumAnimations > 0 )
                    animations[ file.baseFileName ] = new AssetAnimation( scene.mAnimations, scene.mNumAnimations, scene.mMeshes[ 0 ], scene.mRootNode );

                meshes[ file.baseFileName ] = new Mesh( file.fullPath, scene.mMeshes[ 0 ] );
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

            textures[ file.baseFileName ] = new Texture( file.fullPath );
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
        enum shutdown( string aaName, string friendlyName ) = q{
            foreach_reverse( name; $aaName.keys )
            {
                if( !$aaName[ name ].isUsed )
                    logWarning( "$friendlyName ", name, " not used during this run." );

                $aaName[ name ].shutdown();
                $aaName.remove( name );
            }
        }.replaceMap( [ "$aaName": aaName, "$friendlyName": friendlyName ] );

        mixin( shutdown!( q{meshes}, "Mesh" ) );
        mixin( shutdown!( q{textures}, "Texture" ) );
        mixin( shutdown!( q{materials}, "Material" ) );
        mixin( shutdown!( q{animations}, "Animation" ) );
    }
}

/// Obj for a 1x1 square billboard mesh
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
