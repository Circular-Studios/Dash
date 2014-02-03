module graphics.adapters.adapter;
import core.gameobject, core.properties;
import graphics.shaders.shader, graphics.shaders.shaders;
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

	abstract void initialize();
	abstract void shutdown();
	abstract void resize();
	abstract void reload();

	abstract void beginDraw();
	abstract void drawObject( GameObject obj );
	abstract void endDraw();

	abstract void openWindow();
	abstract void closeWindow();
	
	abstract void messageLoop();

	void initializeDeferredRendering()
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
		glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA8, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, null );
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

protected:
	void loadProperties()
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
