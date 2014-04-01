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

abstract class Adapter
{
private:
	GLDeviceContext _deviceContext;
	GLRenderContext _renderContext;

	uint _width, _screenWidth;
	uint _height, _screenHeight;
	bool _fullscreen, _backfaceCulling, _vsync;
	
	uint deferredFrameBuffer;
	uint diffuseRenderTexture; //Alpha channel stores Specular map average
	uint normalRenderTexture; //Alpha channel stores nothing important
	uint depthRenderTexture;
	// Do not add properties for:
	shared mat4 projection;
	shared AmbientLight ambientLight;
	shared DirectionalLight[] directionalLights;
	shared PointLight[] pointLights;
	shared SpotLight[] spotLights;
	shared UserInterface[] uis;

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
	

	/**
	 *  Constant strings for various parts of the render pipeline
	 **/
	enum : string 
	{
		UnitSquare = "unitsquare",
		UnitSphere = "unitsphere",
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
		glGenFramebuffers( 1, &deferredFrameBuffer );
		glBindFramebuffer( GL_FRAMEBUFFER, deferredFrameBuffer );

		//Generate our 3 textures
		glGenTextures( 1, &diffuseRenderTexture );
		glGenTextures( 1, &normalRenderTexture );
		glGenTextures( 1, &depthRenderTexture );

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
		glTexImage2D( GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT32, width, height, 0, GL_DEPTH_COMPONENT, GL_FLOAT, null );
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
		
		
	}
	
	/**
	 * called after all desired objects are drawn
	 * handles lighting and post processing
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

		shared mat4 perspProj = scene.camera.buildPerspective( cast(float)width, cast(float)height );

		void geometryPass()
		{
			foreach( object; scene )
			{
				if( object.mesh )
				{
					// set the shader
					Shader shader = object.mesh.animated
									? Shaders.animatedGeometry
									: Shaders.geometry;

					glUseProgram( shader.programID );
					glBindVertexArray( object.mesh.glVertexArray );

					shader.bindUniformMatrix4fv( ShaderUniform.World, object.transform.matrix );
					shader.bindUniformMatrix4fv( ShaderUniform.WorldViewProjection,
												 perspProj * scene.camera.viewMatrix * object.transform.matrix );

					shader.bindMaterial( object.material );

					glDrawElements( GL_TRIANGLES, object.mesh.numVertices, GL_UNSIGNED_INT, null );

					glBindVertexArray(0);
				}
			}
		}

		void lightPass()
		{
			void bindGeometryOutputs( Shader shader )
			{
				// diffuse
				glUniform1i( shader.getUniformLocation( ShaderUniform.DiffuseTexture ), 0 );
				glActiveTexture( GL_TEXTURE0 );
				glBindTexture( GL_TEXTURE_2D, diffuseRenderTexture );
				
				// normal
				glUniform1i( shader.getUniformLocation( ShaderUniform.NormalTexture ), 1 );
				glActiveTexture( GL_TEXTURE1 );
				glBindTexture( GL_TEXTURE_2D, normalRenderTexture );
				
				// depth
				glUniform1i( shader.getUniformLocation( ShaderUniform.DepthTexture ), 2 );
				glActiveTexture( GL_TEXTURE2 );
				glBindTexture( GL_TEXTURE_2D, depthRenderTexture );
			}

			// Ambient Light
			if( ambientLight !is null )
			{
				auto shader = Shaders[ AmbientLightShader ];
				glUseProgram( shader.programID );

				bindGeometryOutputs( shader );

				shader.bindAmbientLight( ambientLight );
				// bind inverseViewProj for rebuilding world positions from pixel locations
				shader.bindUniformMatrix4fv( ShaderUniform.InverseViewProjection, 
				                            ( perspProj * scene.camera.viewMatrix ).inverse() );

				// bind the window mesh for ambient lights
				glBindVertexArray( Assets.get!Mesh( UnitSquare ).glVertexArray );
				glDrawElements( GL_TRIANGLES, Assets.get!Mesh( UnitSquare ).numVertices, GL_UNSIGNED_INT, null );
			}

			// Directional Lights
			if( directionalLights.length != 0 )
			{
				auto shader = Shaders[ DirectionalLightShader ];
				glUseProgram( shader.programID );

				bindGeometryOutputs( shader );

				// bind inverseViewProj for rebuilding world positions from pixel locations
				shader.bindUniformMatrix4fv( ShaderUniform.InverseViewProjection, 
				                            ( perspProj * scene.camera.viewMatrix ).inverse() );
				shader.setEyePosition( scene.camera.owner.transform.worldPosition );

				// bind the window mesh for directional lights
				glBindVertexArray( Assets.get!Mesh( UnitSquare ).glVertexArray );

				// bind and draw directional lights
				foreach( light; directionalLights )
				{
					shader.bindDirectionalLight( light );
					glDrawElements( GL_TRIANGLES, Assets.get!Mesh( UnitSquare ).numVertices, GL_UNSIGNED_INT, null );
				}
			}

			// Point Lights
			if( pointLights.length != 0 )
			{
				auto shader = Shaders.pointLight;
				glUseProgram( shader.programID );

				bindGeometryOutputs( shader );

				// bind inverseViewProj for rebuilding world positions from pixel locations
				shader.bindUniformMatrix4fv( ShaderUniform.InverseViewProjection, 
				                            ( perspProj * scene.camera.viewMatrix ).inverse() );
				shader.setEyePosition( scene.camera.owner.transform.worldPosition );

				// bind the sphere mesh for point lights
				glBindVertexArray( Assets.get!Mesh( UnitSphere ).glVertexArray );

				// bind and draw point lights
				foreach( light; pointLights )
				{
				//	logInfo(light.owner.name);
					shader.bindUniformMatrix4fv( ShaderUniform.WorldViewProjection, 
												 perspProj * scene.camera.viewMatrix * light.getTransform() );
					shader.bindPointLight( light );
					glDrawElements( GL_TRIANGLES, Assets.get!Mesh( UnitSphere ).numVertices, GL_UNSIGNED_INT, null );
				}
			}
		}

		void uiPass()
		{
			Shader shader = Shaders.userInterface;
			glUseProgram( shader.programID );
			glBindVertexArray( Assets.get!Mesh( UnitSquare ).glVertexArray );
			
			foreach( ui; uis )
			{
				shader.bindUniformMatrix4fv( ShaderUniform.WorldProj, 
					( scene.camera.buildOrthogonal( cast(float)width, cast(float)height ) ) * ui.scaleMat );
				shader.bindUI( ui );
				glDrawElements( GL_TRIANGLES, Assets.get!Mesh( UnitSquare ).numVertices, GL_UNSIGNED_INT, null );

			}

			glBindVertexArray(0);
		}

		glBindFramebuffer( GL_FRAMEBUFFER, deferredFrameBuffer );
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
		ambientLight = null;
		directionalLights = [];
		pointLights = [];
		spotLights = [];
		uis = [];
	}

	/*
	 * Build arrays of lights in the scene to be drawn in endDraw
	 */
	final void addLight( shared Light light )
	{
		auto lightType = typeid( light );

		if( lightType == typeid( AmbientLight ) )
		{
			if( ambientLight is null )
			{
				ambientLight = cast(shared AmbientLight)light;
			}
			else
				logWarning( "Attemtping to add multiple ambient lights to the scene.  ",
											"Ignoring additional ambient lights." );
		}
		else if( lightType == typeid( DirectionalLight ) )
		{
			directionalLights ~= cast(shared DirectionalLight)light;
		}
		else if( lightType == typeid( PointLight ) )
		{
			pointLights ~= cast(shared PointLight)light;
		}
		else if( lightType == typeid( SpotLight ) )
		{
			spotLights ~= cast(shared SpotLight)light;
		}
		else
		{
			logWarning( "Attempting to add unknown light type, light ignored." );
		}
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

private:
	
}
