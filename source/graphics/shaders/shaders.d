/**
* TODO
*/
module graphics.shaders.shaders;
import core, components, graphics, utility;
import graphics.shaders.glsl;

import derelict.opengl3.gl3;
import gl3n.linalg;

import std.string, std.traits, std.algorithm;

/*
 * String constants for our shader uniforms
 */
private enum ShaderUniform
{
    /// Matrices
    World = "world",
    WorldProj = "worldProj", // used this for scaling & orthogonal UI drawing
    WorldView = "worldView",
    WorldViewProjection = "worldViewProj",
    InverseProjection = "invProj",
    /// Floats
    ProjectionConstants = "projectionConstants",
    /// Textures
    UITexture = "uiTexture",
    DiffuseTexture = "diffuseTexture",
    NormalTexture = "normalTexture",
    SpecularTexture = "specularTexture",
    DepthTexture = "depthTexture",
    /// Lights
    LightDirection = "light.direction",
    LightColor = "light.color",
    LightRadius = "light.radius",
    LightFalloffRate = "light.falloffRate",
    LightPosition = "light.pos_v",
    EyePosition = "eyePosition_w",
    /// Animations
    Bones = "bones",
    /// Object data
    ObjectId = "objectId",
}

/**
* TODO
*/
enum ShaderUniformFields = reduce!( ( a, b ) => a ~ "immutable uint " ~ b ~ ";\n" )( "", [__traits(allMembers,ShaderUniform )] );

/**
* TODO
*/
final abstract class Shaders
{
static:
private:
    Shader[string] shaders;

public:
    /// TODO
    Shader geometry;
    /// TODO
    Shader animatedGeometry;
    /// TODO
    Shader ambientLight;
    /// TODO
    Shader directionalLight;
    /// TODO
    Shader pointLight;
    /// TODO
    Shader userInterface;

    /**
    * TODO
    */
    final void initialize()
    {
        geometry = new Shader( "Geometry", geometryVS, geometryFS, true );
        animatedGeometry = new Shader( "AnimatedGeometry", animatedGeometryVS, geometryFS, true ); // Only VS changed, FS stays the same
        ambientLight = new Shader( "AmbientLight", ambientlightVS, ambientlightFS, true );
        directionalLight = new Shader( "DirectionalLight", directionallightVS, directionallightFS, true );
        pointLight = new Shader( "PointLight", pointlightVS, pointlightFS, true );
        userInterface = new Shader( "UserInterface", userinterfaceVS, userinterfaceFS, true );

        foreach( file; FilePath.scanDirectory( FilePath.Resources.Shaders, "*.fs.glsl" ) )
        {
            // Strip .fs from file name
            string name = file.baseFileName[ 0..$-3 ];
            shaders[ name ] = new Shader( name, file.directory ~ "\\" ~ name ~ ".vs.glsl", file.fullPath );
        }

        shaders.rehash();
    }

    /**
    * TODO
    */
    final void shutdown()
    {
        foreach_reverse( index; 0 .. shaders.length )
        {
            auto name = shaders.keys[ index ];
            shaders[ name ].shutdown();
            shaders.remove( name );
        }
    }

    /**
    * TODO
    */
    final Shader opIndex( string name )
    {
        return get( name );
    }

    /**
    * TODO
    */
    final Shader get( string name )
    {
        Shader* shader = name in shaders;
        return shader is null ? null : *shader;
    }
}

/**
* TODO
*/
final package class Shader
{
private:
    uint _programID, _vertexShaderID, _fragmentShaderID;
    string _shaderName;

public:
    /// TODO
    mixin( Property!_programID );
    /// TODO
    mixin( Property!_vertexShaderID );
    /// TODO
    mixin( Property!_fragmentShaderID );
    /// TODO
    mixin( Property!_shaderName );

    mixin( ShaderUniformFields );

    /**
    * TODO
    */
    this(string name, string vertex, string fragment, bool preloaded = false )
    {
        shaderName = name;
        // Create shader
        vertexShaderID = glCreateShader( GL_VERTEX_SHADER );
        fragmentShaderID = glCreateShader( GL_FRAGMENT_SHADER );
        programID = glCreateProgram();

        if(!preloaded)
        {
            auto vertexFile = new FilePath( vertex );
            auto fragmentFile = new FilePath( fragment );
            string vertexBody = vertexFile.getContents();
            string fragmentBody = fragmentFile.getContents();
            compile( vertexBody, fragmentBody );
        }
        else
        {
            compile( vertex, fragment );
        }

        //uniform is the *name* of the enum member not it's value
        foreach( uniform; __traits(allMembers,ShaderUniform ) )
        {
            mixin(uniform) = glGetUniformLocation( programID, mixin("ShaderUniform." ~ uniform).ptr );
        }
    }

    /**
    * TODO
    */
    void compile( string vertexBody, string fragmentBody )
    {
        auto vertexCBody = vertexBody.ptr;
        auto fragmentCBody = fragmentBody.ptr;
        int vertexSize = cast(int)vertexBody.length;
        int fragmentSize = cast(int)fragmentBody.length;

        glShaderSource( vertexShaderID, 1, &vertexCBody, &vertexSize );
        glShaderSource( fragmentShaderID, 1, &fragmentCBody, &fragmentSize );

        GLint compileStatus = GL_TRUE;
        glCompileShader( vertexShaderID );
        glGetShaderiv( vertexShaderID, GL_COMPILE_STATUS, &compileStatus );
        if( compileStatus != GL_TRUE )
        {
            log( OutputType.Error, shaderName ~ " Vertex Shader compile error" );
            char[1000] errorLog;
            auto info = errorLog.ptr;
            glGetShaderInfoLog( vertexShaderID, 1000, null, info );
            log( OutputType.Error, errorLog );
            assert(false);
        }

        glCompileShader( fragmentShaderID );
        glGetShaderiv( fragmentShaderID, GL_COMPILE_STATUS, &compileStatus );
        if( compileStatus != GL_TRUE )
        {
            log( OutputType.Error, shaderName ~ " Fragment Shader compile error" );
            char[1000] errorLog;
            auto info = errorLog.ptr;
            glGetShaderInfoLog( fragmentShaderID, 1000, null, info );
            log( OutputType.Error, errorLog );
            assert(false);
        }

        // Attach shaders to program
        glAttachShader( programID, vertexShaderID );
        glAttachShader( programID, fragmentShaderID );
        glLinkProgram( programID );

        glGetProgramiv( programID, GL_LINK_STATUS, &compileStatus );
        if( compileStatus != GL_TRUE )
        {
            log( OutputType.Error, shaderName ~ " Shader program linking error" );
            char[1000] errorLog;
            auto info = errorLog.ptr;
            glGetProgramInfoLog( programID, 1000, null, info );
            log( OutputType.Error, errorLog );
            assert(false);
        }
    }

    /**
     * Pass through for glUniform1f
     */
    final void bindUniform1f( uint uniform, const float value )
    {
        glUniform1f( uniform, value );
    }

    /**
     * Pass through for glUniform2f
     */
    final void bindUniform2f( uint uniform, const shared vec2 value )
    {
        glUniform2f( uniform, value.x, value.y );
    }

    /**
     * Pass through for glUniform 3f
     * Passes to the shader in XYZ order
     */
    final void bindUniform3f( uint uniform, const shared vec3 value )
    {
        glUniform3f( uniform, value.x, value.y, value.z );
    }

    /**
     * Pass through for glUniform2f
     */
    final void bindUniform1ui( uint uniform, const uint value )
    {
        glUniform1ui( uniform, value );
    }

    /**
     *  pass through for glUniformMatrix4fv
     */
    final void bindUniformMatrix4fv( uint uniform, shared mat4 matrix )
    {
        glUniformMatrix4fv( uniform, 1, true, matrix.value_ptr );
    }

    /**
     * Bind an array of mat4s.
     */
    final void bindUniformMatrix4fvArray( uint uniform, shared mat4[] matrices )
    {
        float[] matptr;
        foreach( matrix; matrices )
        {
            for( int i = 0; i < 16; i++ )
            {
                matptr ~= matrix.value_ptr()[i];
            }
        }
        glUniformMatrix4fv( uniform, cast(int)matrices.length, true, matptr.ptr );
    }

    /**
     * Binds diffuse, normal, and specular textures to the shader
     */
    final void bindMaterial( shared Material material )
    {
        //This is finding the uniform for the given texture, and setting that texture to the appropriate one for the object
        glUniform1i( DiffuseTexture, 0 );
        glActiveTexture( GL_TEXTURE0 );
        glBindTexture( GL_TEXTURE_2D, material.diffuse.glID );

        glUniform1i( NormalTexture, 1 );
        glActiveTexture( GL_TEXTURE1 );
        glBindTexture( GL_TEXTURE_2D, material.normal.glID );

        glUniform1i( SpecularTexture, 2 );
        glActiveTexture( GL_TEXTURE2 );
        glBindTexture( GL_TEXTURE_2D, material.specular.glID );
    }

    /**
     * Binds a UI's texture
     */
     final void bindUI( shared UserInterface ui )
     {
        glUniform1i( UITexture, 0 );
        glActiveTexture( GL_TEXTURE0 );
        glBindTexture( GL_TEXTURE_2D, ui.view.glID );
     }

    /**
     * Bind an ambient light
     */
    final void bindAmbientLight( shared AmbientLight light )
    {
        bindUniform3f( LightColor, light.color );
    }

    /**
     * Bind a directional light
     */
    final void bindDirectionalLight( shared DirectionalLight light )
    {
        bindUniform3f( LightDirection, light.direction);
        bindUniform3f( LightColor, light.color );
    }

    /**
     * Bind a directional light after a modifying transform
     */
    final void bindDirectionalLight( shared DirectionalLight light, shared mat4 transform )
    {
        bindUniform3f( LightDirection, ( transform * shared vec4( light.direction, 0.0f ) ).xyz );
        bindUniform3f( LightColor, light.color );
    }

    /**
     * Bind a point light
     */
    final void bindPointLight( shared PointLight light )
    {
        bindUniform3f( LightColor, light.color );
        bindUniform3f( LightPosition, light.owner.transform.worldPosition );
        bindUniform1f( LightRadius, light.radius );
        bindUniform1f( LightFalloffRate, light.falloffRate );
    }

    /**
     * Bind a point light after a modifying transform
     */
    final void bindPointLight( shared PointLight light, shared mat4 transform )
    {
        bindUniform3f( LightColor, light.color );
        bindUniform3f( LightPosition, ( transform * shared vec4( light.owner.transform.worldPosition, 1.0f ) ).xyz);
        bindUniform1f( LightRadius, light.radius );
        bindUniform1f( LightFalloffRate, light.falloffRate );
    }


    /**
     * Sets the eye position for lighting calculations
     */
    final void setEyePosition( shared vec3 pos )
    {
        glUniform3f( EyePosition, pos.x, pos.y, pos.z );
    }

    /**
     * TODO
     */
    void shutdown()
    {
        // please write me :(
    }
}
