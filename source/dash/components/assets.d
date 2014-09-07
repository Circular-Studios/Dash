/**
 * Defines the static Assets class, a static class which manages all textures, meshes, materials, and animations.
 */
module dash.components.assets;
import dash.core.properties, dash.components, dash.utility;

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
        return new AssetRefT( get!AssetT( name ) );
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
                    logFatal( "Unable to find ", name, " in $array." );
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
        assert(aiIsExtensionSupported(".fbx".toStringz), "fbx format isn't supported by assimp instance!");

        // Load the unitSquare
        unitSquare = new MeshAsset( "", aiImportFileFromMemory(
                                        unitSquareMesh.toStringz, unitSquareMesh.length,
                                        aiProcess_CalcTangentSpace | aiProcess_Triangulate |
                                        aiProcess_JoinIdenticalVertices | aiProcess_SortByPType,
                                        "obj" ).mMeshes[0] );

        foreach( file; scanDirectory( Resources.Meshes ) )
        {
            // Load mesh
            const aiScene* scene = aiImportFile( file.fullPath.toStringz,
                                                 aiProcess_CalcTangentSpace | aiProcess_Triangulate |
                                                 aiProcess_JoinIdenticalVertices | aiProcess_SortByPType );
            assert( scene, "Failed to load scene file '" ~ file.fullPath ~ "' Error: " ~ aiGetErrorString().fromStringz() );

            // If animation data, add animation
            if( file.baseFileName in meshes )
                logWarning( "Mesh ", file.baseFileName, " exsists more than once." );

            // Add mesh
            if( scene.mNumMeshes > 0 )
            {
                auto newMesh = new MeshAsset( file.fullPath, scene.mMeshes[ 0 ] );

                if( scene.mNumAnimations > 0 )
                    newMesh.animationData = new AssetAnimation( scene.mAnimations, scene.mNumAnimations, scene.mMeshes[ 0 ], scene.mRootNode );

                meshes[ file.baseFileName ] = newMesh;
            }
            else
            {
                logWarning( "Assimp did not contain mesh data, ensure you are loading a valid mesh." );
            }

            // Release mesh
            aiReleaseImport( scene );
        }

        foreach( file; scanDirectory( Resources.Textures ) )
        {
            if( file.baseFileName in textures )
               logWarning( "Texture ", file.baseFileName, " exists more than once." );

            textures[ file.baseFileName ] = new TextureAsset( file.fullPath );
        }

        foreach( objFile; loadYamlFiles( Resources.Materials ) )
        {
            Node object = objFile[ 0 ];
            auto name = object[ "Name" ].as!string;

            if( name in materials )
                logWarning( "Material ", name, " exists more than once." );

            auto newMat = cast(Material)createYamlObject[ "Material" ]( object );
            materials[ name ] = newMat;
            materialResources[ objFile[ 1 ] ] ~= newMat;
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
                    logDebug( "Refreshing ", name, "." );
                    asset.refresh();
                }
            }
        }.replace( "$aaName", aaName );

        mixin( refresh!q{meshes} );
        mixin( refresh!q{textures} );

        // Iterate over each file, and it's materials
        refreshYamlObjects!(
            node => cast(MaterialAsset)createYamlObject[ "Material" ]( node ),
            node => node[ "Name" ].get!string in materials,
            ( node, mat ) => materials[ node[ "Name" ].get!string ] = mat,
            mat => materials.remove( mat.name ) )
                ( materialResources );
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
                    logWarning( "$friendlyName ", name, " not used during this run." );

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
    //@ignore
    AssetType asset;

    @field( "Asset" )
    string assetName;

    this() { }
    this( AssetType ass )
    {
        asset = ass;
    }

    /// Gets a reference to it's asset.
    override void initialize()
    {
        if( !asset )
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
