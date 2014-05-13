/**
 * Defines the Material and Texture classes.
 */
module components.material;
import core, components, graphics, utility;

import yaml;
import derelict.opengl3.gl3, derelict.freeimage.freeimage;
import std.variant, std.conv, std.string;

mixin( registerComponents!q{components.material} );

/**
 * A collection of textures that serve different purposes in the rendering pipeline.
 */
@yamlEntry!( q{name => Assets.get!Material( name )} )()
final class Material : Asset
{
private:
    immutable string _name;

public:
    /// The diffuse (or color) map.
    //@field( "Diffuse" )
    Texture diffuse;
    /// The normal map, which specifies which way a face is pointing at a given pixel.
    //@field( "Normal" )
    Texture normal;
    /// The specular map, which specifies how shiny a given point is.
    //@field( "Specular" )
    Texture specular;
    /// The name of the material.
    mixin( Getter!_name );

    /**
     * Default constructor, makes sure everything is initialized to default.
     */
    this( string name )
    {
        super( Resource( "" ) );
        diffuse = specular = defaultTex;
        normal = defaultNormal;
        _name = name;
    }

    /**
     * Create a Material from a Yaml node.
     *
     * Params:
     *  yamlObj =           The YAML object to pull the data from.
     *
     * Returns: A new material with specified maps.
     */
    static Material createFromYaml( Node yamlObj )
    {
        auto obj = new Material( yamlObj[ "Name" ].get!string );
        
        obj.refresh( yamlObj );

        return obj;
    }

    /**
     * Refresh the asset.
     */
    override void refresh() { }

    /**
     * Refresh the asset.
     *
     * Params:
     *  yamlObj =       The new makeup of the material.
     */
    override void refresh( Node yamlObj )
    {
        string prop;

        if( yamlObj.tryFind( "Diffuse", prop ) )
            diffuse = Assets.get!Texture( prop );

        if( yamlObj.tryFind( "Normal", prop ) )
            normal = Assets.get!Texture( prop );

        if( yamlObj.tryFind( "Specular", prop ) )
            specular = Assets.get!Texture( prop );
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
 * TODO
 */
class Texture : Asset
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
    this( ubyte* buffer, string filePath = "" )
    {
        super( Resource( filePath ) );
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
    this( string filePath )
    {
        auto imageData = loadFreeImage( filePath );

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
 * A default black texture.
 */
@property Texture defaultTex()
{
    static Texture def;

    if( !def )
        def = new Texture( [cast(ubyte)0, cast(ubyte)0, cast(ubyte)0, cast(ubyte)255].ptr );

    return def;
}

/**
 * A default gray texture
 */
@property Texture defaultNormal()
{
    static Texture def;

    if( !def )
        def = new Texture( [cast(ubyte)255, cast(ubyte)127, cast(ubyte)127, cast(ubyte)255].ptr );

    return def;
}

static this()
{
    /*initializers[ "Material" ] = ( Node yml, GameObject obj )
    {
        if( yml.isScalar )
        {
            obj.material = Assets.get!Material( yml.get!string );
        }
        else if( yml.isMapping )
        {
            logError( "Inline material definitions are not yet supported." );
        }
        else
        {
            logError( "Unsupported format for Material in ", obj.name, "." );
        }

        return null;
    };

    refreshers[ "Material" ] = ( Node yml, GameObject obj )
    {
        IComponent.initializers[ "Material" ]( yml, obj );
    };*/
}
