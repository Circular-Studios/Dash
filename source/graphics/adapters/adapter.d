/**
* TODO
*/
module graphics.adapters.adapter;
import core, components, graphics, utility;

import gl3n.linalg, gl3n.frustum;
import derelict.opengl3.gl3;

import std.algorithm, std.array;

/**
* TODO
*/
abstract class Adapter
{
private:
    GLDeviceContext _deviceContext;
    GLRenderContext _renderContext;

    uint _width, _screenWidth;
    uint _height, _screenHeight;
    bool _fullscreen, _backfaceCulling, _vsync;

    uint _deferredFrameBuffer;
    uint _diffuseRenderTexture; //Alpha channel stores Specular map average
    uint _normalRenderTexture; //Alpha channel stores nothing important
    uint _depthRenderTexture;
    // Do not add properties for:
    shared UserInterface[] uis;

public:
    /// TODO
    mixin( Property!_deviceContext );
    /// TODO
    mixin( Property!_renderContext );

    /// TODO
    mixin( Property!_width );
    /// TODO
    mixin( Property!_screenWidth );
    /// TODO
    mixin( Property!_height );
    /// TODO
    mixin( Property!_screenHeight );
    /// TODO
    mixin( Property!_fullscreen );
    /// TODO
    mixin( Property!_backfaceCulling );
    /// TODO
    mixin( Property!_vsync );
    /// TODO
    mixin( Property!_deferredFrameBuffer );
    /// TODO
    mixin( Property!_diffuseRenderTexture );
    /// TODO
    mixin( Property!_normalRenderTexture );
    /// TODO
    mixin( Property!_depthRenderTexture );

    /**
    * TODO
    */
    abstract void initialize();
    /**
    * TODO
    */
    abstract void shutdown();
    /**
    * TODO
    */
    abstract void resize();
    /**
    * TODO
    */
    abstract void reload();
    /**
    * TODO
    */
    abstract void swapBuffers();

    /**
    * TODO
    */
    abstract void openWindow();
    /**
    * TODO
    */
    abstract void closeWindow();

    /**
    * TODO
    */
    abstract void messageLoop();

    /**
    * TODO
    */
    final void initializeDeferredRendering()
    {
        //http://www.opengl-tutorial.org/intermediate-tutorials/tutorial-14-render-to-texture/

        //Create the frame buffer, which will contain the textures to render to
        deferredFrameBuffer = 0;
        glGenFramebuffers( 1, &_deferredFrameBuffer );
        glBindFramebuffer( GL_FRAMEBUFFER, _deferredFrameBuffer );

        //Generate our 3 textures
        glGenTextures( 1, &_diffuseRenderTexture );
        glGenTextures( 1, &_normalRenderTexture );
        glGenTextures( 1, &_depthRenderTexture );

        //For each texture, we bind it to our active texture, and set the format and filtering
        glBindTexture( GL_TEXTURE_2D, _diffuseRenderTexture );
        glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA8, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, null );
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );

        glBindTexture( GL_TEXTURE_2D, _normalRenderTexture );
        glTexImage2D( GL_TEXTURE_2D, 0, GL_RGB16F, width, height, 0, GL_RGB, GL_FLOAT, null );
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );

        glBindTexture( GL_TEXTURE_2D, _depthRenderTexture );
        glTexImage2D( GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT32, width, height, 0, GL_DEPTH_COMPONENT, GL_FLOAT, null );
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );

        //And finally set all of these to our frameBuffer
        glFramebufferTexture2D( GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _diffuseRenderTexture, 0 );
        glFramebufferTexture2D( GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT1, GL_TEXTURE_2D, _normalRenderTexture, 0 );
        glFramebufferTexture2D( GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, _depthRenderTexture, 0 );

        GLenum[ 2 ] DrawBuffers = [ GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1 ];
        glDrawBuffers( 2, DrawBuffers.ptr );

        auto status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        if(status != GL_FRAMEBUFFER_COMPLETE )
        {
            string mapFramebufferError(int code)
            {
                switch(code)
                {
                    case(GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT): return "GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT";
                    case(GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT): return "GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT";
                    case(GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER): return "GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER";
                    case(GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER): return "GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER";
                    case(GL_FRAMEBUFFER_UNSUPPORTED): return "GL_FRAMEBUFFER_UNSUPPORTED";
                    case(GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE): return "GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE";
                    case(GL_FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS): return "GL_FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS";
                    default: return "UNKNOWN";
                }
            }

            logFatal( "Deffered rendering Frame Buffer was not initialized correctly. Error: ", mapFramebufferError(status) );
            assert(false);
        }
    }

    /**
     * Sets up the render pipeline.
     */
    final void beginDraw()
    {

    }

    /**
     * Called after all desired objects are drawn.
     * Handles lighting and post processing.
     */
    final void endDraw()
    {
        if( !DGame.instance.activeScene )
        {
            logWarning( "No active scene." );
            return;
        }

        auto scene = DGame.instance.activeScene;

        if( !scene.camera )
        {
            logWarning( "No camera on active scene." );
            return;
        }

        auto objsWithLights = scene.objects
                                .filter!(obj => obj.stateFlags.drawLight && obj.light)
                                .map!(obj => obj.light);

        auto getOfType( Type )()
        {
            return objsWithLights
                    .filter!(obj => typeid(obj) == typeid(Type))
                    .map!(obj => cast(shared Type)obj);
        }

        auto ambientLights = getOfType!AmbientLight;
        auto directionalLights = getOfType!DirectionalLight;
        auto pointLights = getOfType!PointLight;
        auto spotLights = getOfType!SpotLight;

        shared mat4 projection = scene.camera.perspectiveMatrix;
        shared mat4 invProj = scene.camera.inversePerspectiveMatrix;

        /**
        * TODO
        */
        void geometryPass()
        {
            void updateMatricies( shared GameObject current )
            {
                current.transform.updateMatrix();
                foreach( child; current.children )
                    updateMatricies( child );
            }
            updateMatricies( scene.root );

            foreach( object; scene.objects )
            {
                if( object.mesh && object.stateFlags.drawMesh )
                {
                    shared mat4 worldView = scene.camera.viewMatrix * object.transform.matrix;
                    shared mat4 worldViewProj = projection * worldView;

                    if( !( object.mesh.boundingBox in shared Frustum( worldViewProj ) ) )
                    {
                        // If we can't see an object, don't draw it.
                        continue;
                    }

                    // set the shader
                    Shader shader = object.mesh.animated
                                    ? Shaders.animatedGeometry
                                    : Shaders.geometry;

                    glUseProgram( shader.programID );
                    glBindVertexArray( object.mesh.glVertexArray );
                    shader.bindUniformMatrix4fv( shader.WorldView, worldView );
                    shader.bindUniformMatrix4fv( shader.WorldViewProjection, worldViewProj );
                    shader.bindUniform1ui( shader.ObjectId, object.id );

                    if( object.mesh.animated )
                        shader.bindUniformMatrix4fvArray( shader.Bones, object.animation.currBoneTransforms );

                    shader.bindMaterial( object.material );

                    glDrawElements( GL_TRIANGLES, object.mesh.numVertices, GL_UNSIGNED_INT, null );

                    glBindVertexArray(0);
                }
            }
        }

        /**
        * TODO
        */
        void lightPass()
        {
            /**
            * TODO
            */
            void bindGeometryOutputs( Shader shader )
            {
                // diffuse
                glUniform1i( shader.DiffuseTexture, 0 );
                glActiveTexture( GL_TEXTURE0 );
                glBindTexture( GL_TEXTURE_2D, _diffuseRenderTexture );

                // normal
                glUniform1i( shader.NormalTexture, 1 );
                glActiveTexture( GL_TEXTURE1 );
                glBindTexture( GL_TEXTURE_2D, _normalRenderTexture );

                // depth
                glUniform1i( shader.DepthTexture, 2 );
                glActiveTexture( GL_TEXTURE2 );
                glBindTexture( GL_TEXTURE_2D, _depthRenderTexture );
            }

            // Ambient Light
            if( !ambientLights.empty )
            {
                auto shader = Shaders.ambientLight;
                glUseProgram( shader.programID );

                bindGeometryOutputs( shader );

                shader.bindAmbientLight( ambientLights.front );

                // bind the window mesh for ambient lights
                glBindVertexArray( Assets.unitSquare.glVertexArray );
                glDrawElements( GL_TRIANGLES, Assets.unitSquare.numVertices, GL_UNSIGNED_INT, null );

                ambientLights.popFront;

                if( !ambientLights.empty )
                {
                    logWarning( "Only one ambient light per scene is utilized." );
                }
            }

            // Directional Lights
            if( !directionalLights.empty )
            {
                auto shader = Shaders.directionalLight;
                glUseProgram( shader.programID );

                bindGeometryOutputs( shader );

                // bind inverseProj for rebuilding world positions from pixel locations
                shader.bindUniformMatrix4fv( shader.InverseProjection, invProj );
                shader.bindUniform2f( shader.ProjectionConstants, scene.camera.projectionConstants );

                // bind the window mesh for directional lights
                glBindVertexArray( Assets.unitSquare.glVertexArray );

                // bind and draw directional lights
                foreach( light; directionalLights )
                {
                    shader.bindDirectionalLight( light, scene.camera.viewMatrix );
                    glDrawElements( GL_TRIANGLES, Assets.unitSquare.numVertices, GL_UNSIGNED_INT, null );
                }
            }

            // Point Lights
            if( !pointLights.empty )
            {
                auto shader = Shaders.pointLight;
                glUseProgram( shader.programID );

                bindGeometryOutputs( shader );

                // bind WorldView for creating the View rays for reconstruction position
                shader.bindUniform2f( shader.ProjectionConstants, scene.camera.projectionConstants );

                // bind the sphere mesh for point lights
                glBindVertexArray( Assets.unitSquare.glVertexArray );

                // bind and draw point lights
                foreach( light; pointLights )
                {
                //  logInfo(light.owner.name);
                    shader.bindUniformMatrix4fv( shader.WorldView, 
                                                 scene.camera.viewMatrix * light.getTransform() );
                    shader.bindUniformMatrix4fv( shader.WorldViewProjection,
                                                 projection * scene.camera.viewMatrix * light.getTransform() );
                    shader.bindPointLight( light, scene.camera.viewMatrix );
                    glDrawElements( GL_TRIANGLES, Assets.unitSquare.numVertices, GL_UNSIGNED_INT, null );
                }
            }

            // Spot Lights
            if( !spotLights.empty )
            {
                // TODO
            }
        }

        /**
        * TODO
        */
        void uiPass()
        {
            Shader shader = Shaders.userInterface;
            glUseProgram( shader.programID );
            glBindVertexArray( Assets.unitSquare.glVertexArray );

            foreach( ui; uis )
            {
                shader.bindUniformMatrix4fv( shader.WorldProj,
                    scene.camera.orthogonalMatrix * ui.scaleMat );
                shader.bindUI( ui );
                glDrawElements( GL_TRIANGLES, Assets.unitSquare.numVertices, GL_UNSIGNED_INT, null );
            }

            glBindVertexArray(0);
        }

        glBindFramebuffer( GL_FRAMEBUFFER, _deferredFrameBuffer );
        // must be called before glClear to clear the depth buffer, otherwise depth buffer won't be cleared
        glDepthMask( GL_TRUE );
        glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
        glEnable( GL_DEPTH_TEST );
        glDisable( GL_BLEND );

        geometryPass();

        // settings for light pass
        glDepthMask( GL_FALSE );
        glDisable( GL_DEPTH_TEST );
        glEnable( GL_BLEND );
        glBlendFunc( GL_ONE, GL_ONE );

        //This line switches back to the default framebuffer
        glBindFramebuffer( GL_FRAMEBUFFER, 0 );
        glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );

        lightPass();

        glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
        //glBlendEquation( GL_FUNC_ADD );

        uiPass();

        // put it on the screen
        swapBuffers();

        // clean up
        glBindVertexArray(0);
        glUseProgram(0);
        uis = [];
    }

    /*
     * Adds a UI to be drawn over the objects in the scene
     * UIs will be drawn ( and overlap ) in the order they are added
     */
    final void addUI( shared UserInterface ui )
    {
        uis ~= ui;
    }

protected:
    /**
    * TODO
    */
    final void loadProperties()
    {
        fullscreen = Config.get!bool( "Display.Fullscreen" );
        if( fullscreen )
        {
            width = screenWidth;
            height = screenHeight;
        }
        else
        {
            width = Config.get!uint( "Display.Width" );
            height = Config.get!uint( "Display.Height" );
        }

        backfaceCulling = Config.get!bool( "Graphics.BackfaceCulling" );
        vsync = Config.get!bool( "Graphics.VSync" );
    }
}
