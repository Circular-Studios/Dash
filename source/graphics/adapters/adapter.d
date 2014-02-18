module graphics.adapters.adapter;
import core.gameobject, core.properties;
import components;
import graphics.shaders;
import math.vector, math.matrix;
import utility.config, utility.output;

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

abstract class Adapter
{
public:
	// Graphics contexts
	mixin Property!( "GLDeviceContext", "deviceContext", "protected" );
	mixin Property!( "GLRenderContext", "renderContext", "protected" );

	mixin Property!( "uint", "width", "protected" );
	mixin Property!( "uint", "screenWidth", "protected" );
	mixin Property!( "uint", "height", "protected" );
	mixin Property!( "uint", "screenHeight", "protected" );
	mixin Property!( "bool", "fullscreen", "protected" );
	mixin Property!( "bool", "backfaceCulling", "protected" );
	mixin Property!( "bool", "vsync", "protected" );
	mixin Property!( "uint", "deferredFrameBuffer", "protected" );
	mixin Property!( "uint", "diffuseRenderTexture", "protected" ); //Alpha channel stores Specular color
	mixin Property!( "uint", "normalRenderTexture", "protected" ); //Alpha channel stores Specular power
	mixin Property!( "uint", "depthRenderTexture", "protected" );
	
	enum : string 
	{
		GeometryShader = "geometry",
		LightingShader = "lighting",
		WindowMesh = "WindowMesh"
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
		glGenFramebuffers( 1, &_deferredFrameBuffer );
		glBindFramebuffer( GL_FRAMEBUFFER, deferredFrameBuffer );

		//Generate our 3 textures
		glGenTextures( 1, &_diffuseRenderTexture );
		glGenTextures( 1, &_normalRenderTexture );
		glGenTextures( 1, &_depthRenderTexture );

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

		glUseProgram( Shaders[GeometryShader].programID );
	}
	
	/**
	 * draws an object for the geometry pass
	 * beginDraw must be called before any calls of this function
	 * Params:
	 *	object = the object to be drawn
	 */
	final void drawObject( GameObject object )
	{
		// set the shader
		auto shader = Shaders[GeometryShader];
		glBindVertexArray( object.mesh.glVertexArray );

		shader.setUniformMatrix( ShaderUniform.World , object.transform.matrix );
		shader.setUniformMatrix( ShaderUniform.WorldView, object.transform.matrix * 
								 Camera.lookAtLH( new Vector!3( 0, 0, 0), object.transform.position, new Vector!3( 0, 1, 0 ) ) );
		shader.setUniformMatrix( ShaderUniform.WorldViewProjection , object.transform.matrix *
								 Matrix!4.buildPerspective( std.math.PI_2, cast(float)width / cast(float)height, 1, 1000 ) );

		//This is finding the uniform for the given texture, and setting that texture to the appropriate one for the object
		object.material.bind( shader );

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
		
		// bind the window mesh for directional lights
		glBindVertexArray( Assets.get!Mesh( WindowMesh ).glVertexArray );

		// bind the directional and ambient lights
		Light tempDirLight = new DirectionalLight( new Vector!3( 1.0f, 1.0f, 1.0f ), new Vector!3( 0.0f, -1.0f, 0.5f ) );
		shader.bindLight( tempDirLight );
		Light tempAmbLight = new Light( new Vector!3( .2f, .2f, .2f ) );
		shader.bindLight( tempAmbLight );

		glDrawElements( GL_TRIANGLES, 6, GL_UNSIGNED_INT, null );

		glBindVertexArray(0);
		glUseProgram(0);

		swapBuffers();
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
	}
}
