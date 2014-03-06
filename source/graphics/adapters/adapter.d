module graphics.adapters.adapter;
import core, components, graphics, utility;

import gl3n.linalg;
import derelict.opengl3.gl3;

version( Windows )
{
	import win32.windef;
	
	alias HGLRC GLRenderContext;
	alias HDC GLDeviceContext;
}
else version( OSX )
{
	import derelict.opengl3.gl3, derelict.opengl3.cgl;
	
	alias CGLContextObj GLRenderContext;
	alias uint GLDeviceContext;
}
else
{
	import derelict.opengl3.glx, derelict.opengl3.glxext;
	
	//alias OpenGLRenderContext GLRenderContext;
	alias GLXContext GLRenderContext;
	alias uint GLDeviceContext;
}

shared abstract class Adapter
{
private:
	GLDeviceContext _deviceContext;
	GLRenderContext _renderContext;

	uint _width, _screenWidth;
	uint _height, _screenHeight;
	bool _fullscreen, _backfaceCulling, _vsync;
	float _fov, _near, _far;
	uint _deferredFrameBuffer, _diffuseRenderTexture, _normalRenderTexture, _depthRenderTexture;

public:
	mixin( Property!_deviceContext );
	mixin( Property!_renderContext );

	mixin( Property!_width );
	mixin( Property!_screenWidth );
	mixin( Property!_height );
	mixin( Property!_screenHeight );
	mixin( Property!_fullscreen );
	mixin( Property!_backfaceCulling );
	mixin( Property!_vsync );
	mixin( Property!_fov );
	mixin( Property!_near );
	mixin( Property!_far );
	mixin( Property!_deferredFrameBuffer );
	mixin( Property!_diffuseRenderTexture ); //Alpha channel stores Specular color
	mixin( Property!_normalRenderTexture ); //Alpha channel stores Specular power
	mixin( Property!_depthRenderTexture );
	
	enum : string 
	{
		GeometryShader = "geometry",
		AnimatedGeometryShader = "animatedGeometry",
		LightingShader = "lighting",
		WindowMesh = "unitsquare"
	}

	abstract void initialize();
	abstract void shutdown();
	abstract void resize();
	abstract void reload();
	abstract void swapBuffers();

	abstract void openWindow();
	abstract void closeWindow();
	
	abstract void messageLoop();


	final void initializeDeferredRendering()
	{
		//http://www.opengl-tutorial.org/intermediate-tutorials/tutorial-14-render-to-texture/

		//Create the frame buffer, which will contain the textures to render to
		deferredFrameBuffer = 0;
		glGenFramebuffers( 1, cast(uint*)&_deferredFrameBuffer );
		glBindFramebuffer( GL_FRAMEBUFFER, deferredFrameBuffer );

		//Generate our 3 textures
		glGenTextures( 1, cast(uint*)&_diffuseRenderTexture );
		glGenTextures( 1, cast(uint*)&_normalRenderTexture );
		glGenTextures( 1, cast(uint*)&_depthRenderTexture );

		//For each texture, we bind it to our active texture, and set the format and filtering
		glBindTexture( GL_TEXTURE_2D, diffuseRenderTexture );
		glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA8, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, null );
		glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
		glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
		glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
		glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );

		glBindTexture( GL_TEXTURE_2D, normalRenderTexture );
		glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA16F, width, height, 0, GL_RGBA, GL_FLOAT, null );
		glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
		glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
		glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
		glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );

		glBindTexture( GL_TEXTURE_2D, depthRenderTexture );
		glTexImage2D( GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT32, width, height, 0, GL_DEPTH_COMPONENT, GL_UNSIGNED_INT, null );
		glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
		glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
		glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
		glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );

		//And finally set all of these to our frameBuffer
		glFramebufferTexture2D( GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, diffuseRenderTexture, 0 );
		glFramebufferTexture2D( GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT1, GL_TEXTURE_2D, normalRenderTexture, 0 );
		glFramebufferTexture2D( GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, depthRenderTexture, 0 );

		GLenum[ 2 ] DrawBuffers = [ GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1 ];
		glDrawBuffers( 2, DrawBuffers.ptr );
		glViewport(0, 0, width, height);
		updateProjection();

		if( glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE )
		{
			log( OutputType.Error, "Deffered rendering Frame Buffer was not initialized correctly.");
			assert(false);
		}
	}
	
	/**
	 * sets up the rendering pipeline for the geometry pass
	 */
	final void beginDraw()
	{
		glBindFramebuffer( GL_FRAMEBUFFER, deferredFrameBuffer );
	
		// must be called before glClear to clear the depth buffer, otherwise
		// depth buffer won't be cleared
		glDepthMask( GL_TRUE );

		glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
		
		glEnable( GL_DEPTH_TEST );
		glDisable( GL_BLEND );

		
	}

	/**
	 * draws an object for the geometry pass
	 * beginDraw must be called before any calls of this function
	 * Params:
	 *	object = the object to be drawn
	 */
	final void drawObject( shared GameObject object )
	{
		// set the shader
		shared Shader shader;
		if( object.mesh.animated )
		{
			glUseProgram( Shaders[AnimatedGeometryShader].programID );
			shader = Shaders[AnimatedGeometryShader];
			
		}
		else // not animated mesh
		{
			glUseProgram( Shaders[GeometryShader].programID );
			shader = Shaders[GeometryShader];
		}

		glBindVertexArray( object.mesh.glVertexArray );

		shader.bindUniformMatrix4fv( ShaderUniform.World , object.transform.matrix );
		shader.bindUniformMatrix4fv( ShaderUniform.WorldViewProjection , projection * 
										( ( activeCamera !is null ) ? activeCamera.viewMatrix : mat4.identity ) *
										object.transform.matrix );

		shader.bindMaterial( object.material );

		glDrawElements( GL_TRIANGLES, object.mesh.numVertices, GL_UNSIGNED_INT, null );

		glBindVertexArray(0);
	}
	
	/**
	 * called after all desired objects are drawn
	 * handles lighting and post processing
	 */
	final void endDraw()
	{
		// settings for light pass
		glDepthMask( GL_FALSE );
		glDisable( GL_DEPTH_TEST );
		glEnable( GL_BLEND );
		// glBlendEquation( GL_FUNC_ADD );
		// glBlendFunc(GL_ONE, GL_ONE );
		
		//This line switches back to the default framebuffer
		glBindFramebuffer( GL_FRAMEBUFFER, 0 );
		glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );

		auto shader = Shaders[LightingShader];
		glUseProgram( shader.programID );
		
		// bind geometry pass textures
		GLint textureLocation = shader.getUniformLocation( ShaderUniform.DiffuseTexture );
		glUniform1i( textureLocation, 0 );
		glActiveTexture( GL_TEXTURE0 );
		glBindTexture( GL_TEXTURE_2D, diffuseRenderTexture );

		textureLocation = shader.getUniformLocation( ShaderUniform.NormalTexture );
		glUniform1i( textureLocation, 1 );
		glActiveTexture( GL_TEXTURE1 );
		glBindTexture( GL_TEXTURE_2D, normalRenderTexture );

		textureLocation = shader.getUniformLocation( ShaderUniform.DepthTexture );
		glUniform1i( textureLocation, 2 );
		glActiveTexture( GL_TEXTURE2 );
		glBindTexture( GL_TEXTURE_2D, depthRenderTexture );
		
		// bind the directional and ambient lights
		if( directionalLight is null )
		{
			directionalLight = new shared DirectionalLight( vec3(), vec3() );
		}
		if( ambientLight is null )
		{
			ambientLight = new shared AmbientLight( vec3() );
		}
		shader.bindDirectionalLight( directionalLight );
		shader.bindAmbientLight( ambientLight );
		
		// bind the window mesh for directional lights
		glBindVertexArray( Assets.get!Mesh( WindowMesh ).glVertexArray );
		glDrawElements( GL_TRIANGLES, 6, GL_UNSIGNED_INT, null );

		glBindVertexArray(0);
		glUseProgram(0);

		swapBuffers();

		lights = [];
		ambientLight = null;
		directionalLight = null;
	}

	final void addLight( shared Light light )
	{
		if( typeid( light ) == typeid( AmbientLight ) )
		{
			if( ambientLight is null )
			{
				ambientLight = cast(shared AmbientLight)light;
			}
			else
				log( OutputType.Info, "Attemtping to add multiple ambient lights to the scene.  Ignoring additional ambient lights." );
		}
		else if( typeid( light ) == typeid( DirectionalLight ) )
		{
			if( directionalLight is null )
			{
				directionalLight = cast(shared DirectionalLight)light;
			}
			else
				log( OutputType.Info, "Attemtping to add multiple directional lights to the scene.  Ignoring additional directional lights." );
		}
		else
		{
			lights ~= light;
		}
	}

	final void setCamera( shared Camera camera )
	{
		activeCamera = camera;
	}

protected:
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
		fov = Config.get!float( "Display.FieldOfView" );
		near = Config.get!float( "Display.NearPlane" );
		far = Config.get!float( "Display.FarPlane" );
	}

	final void updateProjection()
	{
		projection = mat4.perspective( cast(float)width, cast(float)height, fov, near, far );
	}

private:
	Camera activeCamera;
	mat4 projection;
	//To be cleared after a draw call:
	AmbientLight ambientLight;
	DirectionalLight directionalLight;
	Light[] lights;
}
