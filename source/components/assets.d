/**
 * Defines the static Assets class, a static class which manages all textures, meshes, materials, and animations.
 */
module components.assets;
import components, utility;

import std.string;
import std.exception;

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
public:
    Mesh unitSquare;

    /**
     * Get the asset with the given type and name.
     */
    final shared(T) get( T )( string name ) if( is( T == Mesh ) || is( T == Texture ) || is( T == Material ) || is( T == AssetAnimation ))
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
        else static if( is( T == AssetAnimation ) )
        {
            return animations[ name ];
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
            enforce(scene, "Failed to load scene file '" ~ file.fullPath ~ "' Error: " ~ aiGetErrorString().fromStringz);
            
            // If animation data, add animation
            if(scene.mNumAnimations > 0)
                animations[ file.baseFileName ] = new shared AssetAnimation( scene.mAnimations[0], scene.mMeshes[0], scene.mRootNode );

            // Add mesh
            meshes[ file.baseFileName ] = new shared Mesh( file.fullPath, scene.mMeshes[0] );

            // Release mesh
            aiReleaseImport( scene );
        }

        foreach( file; FilePath.scanDirectory( FilePath.Resources.Textures ) )
        {
            textures[ file.baseFileName ] = new shared Texture( file.fullPath );
        }

        foreach( object; loadYamlDocuments( FilePath.Resources.Materials ) )
        {
            auto name = object[ "Name" ].as!string;
            
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
            materials[ name ].shutdown();
            materials.remove( name );
        }
        foreach_reverse( index; 0 .. animations.length )
        {
            auto name = animations.keys[ index ];
            animations[ name ].shutdown();
            animations.remove( name );
        }
    }

private:
    Mesh[string] meshes;
    Texture[string] textures;
    Material[string] materials;
    AssetAnimation[string] animations;
}

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