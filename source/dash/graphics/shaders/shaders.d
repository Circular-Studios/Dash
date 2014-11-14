/**
* Defines Shader class and the Shaders collection for loading, binding, and setting values in GLSL shaders
*/
module dash.graphics.shaders.shaders;
import dash.core, dash.components, dash.graphics, dash.utility;
import dash.graphics.shaders.glsl;

import derelict.opengl3.gl3;

import std.string, std.traits, std.algorithm, std.array, std.regex;

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
    LightProjectionView = "lightProjView",
    CameraView = "cameraView",
    /// Floats
    ProjectionConstants = "projectionConstants",
    /// Textures
    UITexture = "uiTexture",
    DiffuseTexture = "diffuseTexture",
    NormalTexture = "normalTexture",
    SpecularTexture = "specularTexture",
    DepthTexture = "depthTexture",
    ShadowMap = "shadowMap",
    /// Lights
    LightDirection = "light.direction",
    LightColor = "light.color",
    LightRadius = "light.radius",
    LightFalloffRate = "light.falloffRate",
    LightPosition = "light.pos_v",
    LightShadowless = "light.shadowless",
    EyePosition = "eyePosition_w",
    /// Animations
    Bones = "bones",
    /// Object data
    ObjectId = "objectId",
}

/**
* A constant string representing immutable uint fields for each ShaderUniform enum values
*/
enum ShaderUniformFields = reduce!( ( a, b ) => a ~ "immutable uint " ~ b ~ ";\n" )( "", [__traits(allMembers,ShaderUniform )] );

/**
* Loads necessary shaders into variables, and any custom user shaders into an associative array
*/
final abstract class Shaders
{
static:
private:
    Shader[string] shaders;

public:
    /// Geometry Shader
    Shader geometry;
    /// Animated Geometry Shader
    Shader animatedGeometry;
    /// Ambient Lighting Shader
    Shader ambientLight;
    /// Directional Lighting shader
    Shader directionalLight;
    /// Point Lighting shader
    Shader pointLight;
    /// User Interface shader
    Shader userInterface;
    /// Shader for depth of inanimate objects.
    Shader shadowMap;
    /// Shader for depth of animated objects.
    Shader animatedShadowMap;

    /**
    * Loads the field-shaders first, then any additional shaders in the Shaders folder
    */
    final void initialize()
    {
        geometry = new Shader( "Geometry", geometryVS, geometryFS, true );
        animatedGeometry = new Shader( "AnimatedGeometry", animatedGeometryVS, geometryFS, true ); // Only VS changed, FS stays the same
        ambientLight = new Shader( "AmbientLight", ambientlightVS, ambientlightFS, true );
        directionalLight = new Shader( "DirectionalLight", directionallightVS, directionallightFS, true );
        pointLight = new Shader( "PointLight", pointlightVS, pointlightFS, true );
        userInterface = new Shader( "UserInterface", userinterfaceVS, userinterfaceFS, true );
        shadowMap = new Shader( "ShadowMap", shadowmapVS, shadowmapFS, true );
        animatedShadowMap = new Shader( "AnimatedShadowMap", animatedshadowmapVS, shadowmapFS, true );

        foreach( file; scanDirectory( Resources.Shaders, "*.fs.glsl" ) )
        {
            // Strip .fs from file name
            string name = file.baseFileName[ 0..$-3 ];
            shaders[ name ] = new Shader( name, file.directory ~ "\\" ~ name ~ ".vs.glsl", file.fullPath );
        }

        shaders.rehash();
    }

    /**
    * Empties the array of shaders and calls their Shutdown function
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
    * Returns a Shader based on its string name
    */
    final Shader opIndex( string name )
    {
        return get( name );
    }

    /**
    * Returns a Shader based on its string name
    */
    final Shader get( string name )
    {
        Shader* shader = name in shaders;
        return shader is null ? null : *shader;
    }
}

/**
* Class storing the programID, VS ID, FS ID and ShaderUniform locations for a given Shader program
*/
final package class Shader
{
private:
    uint _programID, _vertexShaderID, _fragmentShaderID;
    string _shaderName;
    auto versionRegex = ctRegex!r"\#version\s400";
    auto layoutRegex = ctRegex!r"layout\(location\s\=\s[0-9]+\)\s";

public:
    /// The program ID for the shader
    mixin( Property!_programID );
    /// The ID for the vertex shader
    mixin( Property!_vertexShaderID );
    /// The ID for the fragment shader
    mixin( Property!_fragmentShaderID );
    /// The string name of the Shader
    mixin( Property!_shaderName );
    /// Uint locations for each possible Shader Uniform
    mixin( ShaderUniformFields );

    /**
    * Creates a Shader Program from the name, and either the vertex and fragment shader strings, or their file names
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
            auto vertexFile = Resource( vertex );
            auto fragmentFile = Resource( fragment );
            string vertexBody = vertexFile.readText();
            string fragmentBody = fragmentFile.readText();

            //If we're using OpenGL 3.3 then we need to
            //change our GLSL version to match, and remove
            //any layout(location = x) qualifiers (they
            //aren't supported in GLSL 330)
            if(config.graphics.usingGl33)
            {
                vertexBody = replaceAll(vertexBody, layoutRegex, ""); 
                vertexBody = replaceAll(vertexBody, versionRegex, "#version 330"); 

                fragmentBody = replaceAll(fragmentBody, layoutRegex, ""); 
                fragmentBody = replaceAll(fragmentBody, versionRegex, "#version 330"); 

                trace( vertexBody );
            }

            compile( vertexBody, fragmentBody );
        }
        else
        {
            if(config.graphics.usingGl33)
            {
                    vertex = replaceAll(vertex, layoutRegex, ""); 
                    vertex = replaceAll(vertex, versionRegex, "#version 330"); 

                    fragment = replaceAll(fragment, layoutRegex, ""); 
                    fragment = replaceAll(fragment, versionRegex, "#version 330"); 
            }

            compile( vertex, fragment );
        }

        //uniform is the *name* of the enum member not it's value
        foreach( uniform; __traits( allMembers, ShaderUniform ) )
        {
            mixin(uniform) = glGetUniformLocation( programID, mixin("ShaderUniform." ~ uniform).ptr );
        }
    }

    /**
    * Compiles a Vertex and Fragment shader into a Shader Program
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
            errorf( "%s Vertex Shader compile error", shaderName );
            char[1000] errorLog;
            auto info = errorLog.ptr;
            glGetShaderInfoLog( vertexShaderID, 1000, null, info );
            error( errorLog );
            assert(false);
        }

        glCompileShader( fragmentShaderID );
        glGetShaderiv( fragmentShaderID, GL_COMPILE_STATUS, &compileStatus );
        if( compileStatus != GL_TRUE )
        {
            errorf( "%s Fragment Shader compile error", shaderName );
            char[1000] errorLog;
            auto info = errorLog.ptr;
            glGetShaderInfoLog( fragmentShaderID, 1000, null, info );
            error( errorLog );
            assert(false);
        }

        // Attach shaders to program
        glAttachShader( programID, vertexShaderID );
        glAttachShader( programID, fragmentShaderID );
        glLinkProgram( programID );

        glGetProgramiv( programID, GL_LINK_STATUS, &compileStatus );
        if( compileStatus != GL_TRUE )
        {
            errorf( "%s Shader program linking error", shaderName );
            char[1000] errorLog;
            auto info = errorLog.ptr;
            glGetProgramInfoLog( programID, 1000, null, info );
            error( errorLog );
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
    final void bindUniform2f( uint uniform, const vec2f value )
    {
        glUniform2f( uniform, value.x, value.y );
    }

    /**
     * Pass through for glUniform 3f
     * Passes to the shader in XYZ order
     */
    final void bindUniform3f( uint uniform, const vec3f value )
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
    final void bindUniformMatrix4fv( uint uniform, mat4f matrix )
    {
        glUniformMatrix4fv( uniform, 1, true, matrix.value_ptr );
    }

    /**
     * Bind an array of mat4s.
     */
    final void bindUniformMatrix4fvArray( uint uniform, mat4f[] matrices )
    {
        auto matptr = appender!(float[]);
        foreach( matrix; matrices )
        {
            matptr ~= matrix.value_ptr()[0..16];
        }
        glUniformMatrix4fv( uniform, cast(int)matrices.length, true, matptr.data.ptr );
    }

    /**
     * Binds diffuse, normal, and specular textures to the shader
     */
    final void bindMaterial( Material material )
    in
    {
        assert( material, "Cannot bind null material." );
        assert( material.diffuse && material.normal && material.specular, "Material must have diffuse, normal, and specular components." );
    }
    body
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
    final void bindUI( UserInterface ui )
    {
        // This is part of a bigger problem. But in the interest of dope screenshots...
        version( OSX )
        if( !ui.view )
            return;

        glUniform1i( UITexture, 0 );
        glActiveTexture( GL_TEXTURE0 );
        glBindTexture( GL_TEXTURE_2D, ui.view.glID );
    }

    /**
     * Bind an ambient light
     */
    final void bindAmbientLight( AmbientLight light )
    {
        bindUniform3f( LightColor, light.color );
    }

    /**
     * Bind a directional light
     */
    final void bindDirectionalLight( DirectionalLight light )
    {
        bindUniform3f( LightDirection, light.direction);
        bindUniform3f( LightColor, light.color );
        bindUniform1f( LightShadowless, cast(float)(!light.castShadows) );
    }

    /**
     * Bind a directional light after a modifying transform
     */
    final void bindDirectionalLight( DirectionalLight light, mat4f transform )
    {
        bindUniform3f( LightDirection, ( transform * vec4f( light.direction, 0.0f ) ).xyz );
        bindUniform3f( LightColor, light.color );
        bindUniform1f( LightShadowless, cast(float)(!light.castShadows) );
    }

    /**
     * Bind a point light
     */
    final void bindPointLight( PointLight light )
    {
        bindUniform3f( LightColor, light.color );
        bindUniform3f( LightPosition, light.owner.transform.worldPosition );
        bindUniform1f( LightRadius, light.radius );
        bindUniform1f( LightFalloffRate, light.falloffRate );
    }

    /**
     * Bind a point light after a modifying transform
     */
    final void bindPointLight( PointLight light, mat4f transform )
    {
        bindUniform3f( LightColor, light.color );
        bindUniform3f( LightPosition, ( transform * vec4f( light.owner.transform.worldPosition, 1.0f ) ).xyz);
        bindUniform1f( LightRadius, light.radius );
        bindUniform1f( LightFalloffRate, light.falloffRate );
    }


    /**
     * Sets the eye position for lighting calculations
     */
    final void setEyePosition( vec3f pos )
    {
        glUniform3f( EyePosition, pos.x, pos.y, pos.z );
    }

    /**
     * Clean up the shader
     */
    void shutdown()
    {
        glDeleteProgram( programID );
    }
}
