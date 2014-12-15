/**
 * Defines the static Assets class, a static class which manages all textures, meshes, materials, and animations.
 */
module dash.components.assets;
import dash.core.properties, dash.components, dash.utility;
import dash.utility.data.serialization;

import std.string, std.array, std.algorithm;

import yaml;
import derelict.freeimage.freeimage, derelict.assimp3.assimp;

/**
 * Assets manages all assets that aren't code, GameObjects, or Prefabs.
 */
abstract final class Assets
{
static:
private:
    MaterialAsset[][Resource] materialResources;

package:
    MeshAsset[string] meshes;
    TextureAsset[string] textures;
    MaterialAsset[string] materials;

public:
    /// Basic quad, generally used for billboarding.
    Mesh unitSquare;

    /**
     * Get a reference to the asset with the given type and name.
     */
    AssetRefT get( AssetRefT )( string name ) if( is( AssetRefT AssetT : AssetRef!AssetT ) && !is( AssetRefT == AssetRef!AssetT ) )
    {
        static if( is( AssetRefT AssetT : AssetRef!AssetT ) )
            return new AssetRefT( getAsset!AssetT( name ) );
        else static assert( false );
    }

    /**
     * Get the asset with the given type and name.
     */
    AssetT getAsset( AssetT )( string name ) if( is( AssetT : Asset ) )
    {
        enum get( Type, string array ) = q{
            static if( is( AssetT == $Type ) )
            {
                if( auto result = name in $array )
                {
                    result.isUsed = true;
                    return *result;
                }
                else
                {
                    errorf( "Unable to find %s in $array.", name );
                    return null;
                }
            }
        }.replaceMap( [ "$array": array, "$Type": Type.stringof ] );

        mixin( get!( MeshAsset, q{meshes} ) );
        mixin( get!( TextureAsset, q{textures} ) );
        mixin( get!( MaterialAsset, q{materials} ) );
    }

    /**
     * Load all assets in the FilePath.ResourceHome folder.
     */
    void initialize()
    {
        DerelictFI.load();

        // Initial assimp start
        DerelictASSIMP3.load();

        // Make sure fbxs are supported.
        assert( aiIsExtensionSupported( ".fbx".toStringz ), "fbx format isn't supported by assimp instance!" );

        enum aiImportOptions = aiProcess_CalcTangentSpace | aiProcess_Triangulate | aiProcess_JoinIdenticalVertices | aiProcess_SortByPType;

        // Load the unitSquare
        unitSquare = new Mesh( new MeshAsset( internalResource, aiImportFileFromMemory(
                                        unitSquareMesh.toStringz(), unitSquareMesh.length,
                                        aiImportOptions, "obj" ).mMeshes[0] ) );

        foreach( file; scanDirectory( Resources.Meshes ) )
        {
            // Load mesh
            const aiScene* scene = aiImportFile( file.fullPath.toStringz, aiImportOptions );
            assert( scene, "Failed to load scene file '" ~ file.fullPath ~ "' Error: " ~ aiGetErrorString().fromStringz() );

            // Add mesh
            if( scene.mNumMeshes > 0 )
            {
                if( file.baseFileName in meshes )
                    warning( "Mesh ", file.baseFileName, " exsists more than once." );

                auto newMesh = new MeshAsset( file, scene.mMeshes[ 0 ] );

                if( scene.mNumAnimations > 0 )
                    newMesh.animationData = new AnimationData( file, scene.mAnimations, scene.mNumAnimations, scene.mMeshes[ 0 ], scene.mRootNode );

                meshes[ file.baseFileName ] = newMesh;
            }
            else
            {
                warning( "Assimp did not contain mesh data, ensure you are loading a valid mesh." );
            }

            // Release mesh
            aiReleaseImport( scene );
        }

        // Load animations
        foreach( file; scanDirectory( Resources.Animation ) )
        {
            // Get the folder name (The mesh name)
            import std.path: dirSeparator;
            auto meshName = file.directory;
            while( meshName.countUntil( dirSeparator ) >= 0 )
                meshName = meshName[ meshName.countUntil( dirSeparator )+1..$ ];

            // If animation and the animations mesh exists
            if( meshes[ meshName ].animationData )
            {
                // Load scene
                const aiScene* scene = aiImportFile( file.fullPath.toStringz, aiImportOptions );
                assert( scene, "Failed to load scene file '" ~ file.fullPath ~ "' Error: " ~ aiGetErrorString().fromStringz() );
                
                if( scene.mNumAnimations > 0 )
                {
                    meshes[ meshName ].animationData.addAnimationSet( file.baseFileName, scene.mAnimations[ 0 ], 24 ); // ?
                }
                
                // Release scene
                aiReleaseImport( scene );
            }
        }

        foreach( file; scanDirectory( Resources.Textures ) )
        {
            if( file.baseFileName in textures )
               warningf( "Texture %s exists more than once.", file.baseFileName );

            textures[ file.baseFileName ] = new TextureAsset( file );
        }

        foreach( res; scanDirectory( Resources.Materials ) )
        {
            auto newMat = deserializeMultiFile!MaterialAsset( res );

            foreach( mat; newMat )
            {
                if( mat.name in materials )
                    warningf( "Material %s exists more than once.", mat.name );

                mat.resource = res;
                materials[ mat.name ] = mat;
                materialResources[ res ] ~= mat;
            }
        }

        meshes.rehash();
        textures.rehash();
        materials.rehash();
        materialResources.rehash();
    }

    /**
     * Refresh the assets that have changed.
     */
    void refresh()
    {
        enum refresh( string aaName ) = q{
            foreach_reverse( name; $aaName.keys )
            {
                auto asset = $aaName[ name ];
                if( !asset.resource.exists )
                {
                    asset.shutdown();
                    $aaName.remove( name );
                }
                else if( asset.resource.needsRefresh )
                {
                    tracef( "Refreshing %s.", name );
                    asset.refresh();
                }
            }
        }.replace( "$aaName", aaName );

        mixin( refresh!q{meshes} );
        mixin( refresh!q{textures} );

        // Iterate over each file, and it's materials
        //TODO: Implement
    }

    /**
     * Unload and destroy all stored assets.
     */
    void shutdown()
    {
        enum shutdown( string aaName, string friendlyName ) = q{
            foreach_reverse( name; $aaName.keys )
            {
                if( !$aaName[ name ].isUsed )
                    warningf( "$friendlyName %s not used during this run.", name );

                $aaName[ name ].shutdown();
                $aaName.remove( name );
            }
        }.replaceMap( [ "$aaName": aaName, "$friendlyName": friendlyName ] );

        mixin( shutdown!( q{meshes}, "Mesh" ) );
        mixin( shutdown!( q{textures}, "Texture" ) );
        mixin( shutdown!( q{materials}, "Material" ) );
    }
}

abstract class Asset
{
private:
    bool _isUsed;

public:
    /// Whether or not the material is actually used.
    mixin( Property!( _isUsed, AccessModifier.Package ) );
    /// The resource containing this asset.
    @ignore
    Resource resource;

    /**
     * Creates asset with resource.
     */
    this( Resource res )
    {
        resource = res;
    }

    void initialize() { }
    void update() { }
    void refresh() { }
    void shutdown() { }
}

/**
 * A reference to an asset.
 */
abstract class AssetRef( AssetType ) : Component if( is( AssetType : Asset ) )
{
public:
    @ignore
    AssetType asset;

    @rename( "Asset" )
    string assetName;

    this() { }
    this( AssetType ass )
    {
        asset = ass;
        initialize();
    }

    /// Is the asset null?
    bool isNull() @property const pure @safe nothrow 
    {
        return asset is null;
    }

    /// Gets a reference to it's asset.
    override void initialize()
    {
        if( !asset && assetName )
            asset = Assets.getAsset!AssetType( assetName );
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
