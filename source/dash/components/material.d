/**
 * Defines the Material and Texture classes.
 */
module dash.components.material;
import dash.core, dash.components, dash.graphics, dash.utility;

import yaml;
import derelict.opengl3.gl3, derelict.freeimage.freeimage;
import std.variant, std.conv, std.string;

mixin( registerComponents!() );

/**
 * A collection of textures that serve different purposes in the rendering pipeline.
 */
final class MaterialAsset : Asset
{
public:
    /// The name of the material.
    @rename( "Name" )
    string name;
    /// The diffuse (or color) map.
    @rename( "Diffuse" ) @asArray @optional
    Texture diffuse;
    /// The normal map, which specifies which way a face is pointing at a given pixel.
    @rename( "Normal" ) @asArray @optional
    Texture normal;
    /// The specular map, which specifies how shiny a given point is.
    @rename( "Specular" ) @asArray @optional
    Texture specular;

    /**
     * Default constructor, makes sure everything is initialized to default.
     */
    this( string name = "" )
    {
        super( internalResource );
        diffuse = specular = defaultTex;
        normal = defaultNormal;
        this.name = name;
    }

    /**
     * Duplicate the material.
     */
    MaterialAsset clone()
    {
        auto mat = new MaterialAsset;
        mat.diffuse = diffuse;
        mat.normal = normal;
        mat.specular = specular;
        mat.name = name;
        return mat;
    }

    /**
     * Shuts down the material, making sure all references are released.
     */
    override void shutdown()
    {
        diffuse = specular = normal = null;
    }
}

/**
 * A reference to a material.
 */
final class Material : AssetRef!MaterialAsset
{
    alias asset this;

    this() { }
    this( MaterialAsset ass )
    {
        super( ass );
    }

    override void initialize()
    {
        super.initialize();

        // All materials should be unique.
        if( asset )
            asset = asset.clone();

        asset.diffuse.initialize();
        asset.normal.initialize();
        asset.specular.initialize();
    }
}

/**
 * TODO
 */
class TextureAsset : Asset
{
protected:
    uint _width = 1;
    uint _height = 1;
    uint _glID;

    /**
     * TODO
     *
     * Params:
     */
    this( ubyte* buffer, Resource filePath )
    {
        super( filePath );
        glGenTextures( 1, &_glID );
        glBindTexture( GL_TEXTURE_2D, glID );
        updateBuffer( buffer );
    }

    /**
     * TODO
     *
     * Params:
     */
    void updateBuffer( const ubyte* buffer )
    {
        // Set texture to update
        glBindTexture( GL_TEXTURE_2D, glID );

        // Update texture
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA, _width, _height, 0, GL_BGRA, GL_UNSIGNED_BYTE, buffer );
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    }

public:
    /// TODO
    mixin( Property!_width );
    /// TODO
    mixin( Property!_height );
    /// TODO
    mixin( Property!_glID );

    /**
     * TODO
     *
     * Params:
     */
    this( Resource filePath )
    {
        auto imageData = loadFreeImage( filePath.fullPath );

        this( cast(ubyte*)FreeImage_GetBits( imageData ), filePath );

        FreeImage_Unload( imageData );
    }

    /**
     * Refresh the asset.
     */
    override void refresh()
    {
        auto imageData = loadFreeImage( resource.fullPath );

        updateBuffer( cast(ubyte*)FreeImage_GetBits( imageData ) );

        FreeImage_Unload( imageData );
    }

    /**
     * TODO
     */
    override void shutdown()
    {
        glBindTexture( GL_TEXTURE_2D, 0 );
        glDeleteBuffers( 1, &_glID );
    }

private:
    auto loadFreeImage( string filePath )
    {
        filePath ~= '\0';
        auto imageData = FreeImage_ConvertTo32Bits( FreeImage_Load( FreeImage_GetFileType( filePath.ptr, 0 ), filePath.ptr, 0 ) );

        width = FreeImage_GetWidth( imageData );
        height = FreeImage_GetHeight( imageData );

        return imageData;
    }
}

/**
 * A reference to a texture.
 */
class Texture : AssetRef!TextureAsset
{
    alias asset this;

    this() { }
    this( TextureAsset ass )
    {
        super( ass );
    }
}

/**
 * A default black texture.
 */
@property Texture defaultTex()
{
    static Texture def;

    if( !def )
        def = new Texture( new TextureAsset( [cast(ubyte)0, cast(ubyte)0, cast(ubyte)0, cast(ubyte)255].ptr, internalResource ) );

    return def;
}

/**
 * A default gray texture
 */
@property Texture defaultNormal()
{
    static Texture def;

    if( !def )
        def = new Texture( new TextureAsset( [cast(ubyte)255, cast(ubyte)127, cast(ubyte)127, cast(ubyte)255].ptr, internalResource ) );

    return def;
}
