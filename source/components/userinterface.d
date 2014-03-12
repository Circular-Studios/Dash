/**
 * Handles the creation and life cycle of a web view
 */

module components.userinterface;
import core;
import utility.awesomium, components;
import std.string;

class UserInterface : GameObject
{
private:
	uint _height;
	uint _width;
	AwesomiumView view;

	// TODO: Handle JS

public:
	this() 
	{
		// Create object with uiMesh and default material
		super();

		view = new AwesomiumView(800,800,"http://google.com",this);
		addComponent( view );
		this.material.diffuse = view;

	}

	override void onUpdate()
	{
		// Check for mouse & keyboard input

		view.update();

		return;
	}

	override void onDraw()
	{

	}

	override void onShutdown()
	{
		// Clean up mesh, material, and view
	}

	void keyPress(int key)
	{

	}
}

class AwesomiumView : Texture, IComponent
{
private:
	awe_webview* webView;
	awe_string* urlString;
	ubyte[] glBuffer;

public:
	this( uint w, uint h, string filePath, GameObject owner )
	{
		_width = w;
		_height = h;
		glBuffer = new ubyte[_width*_height*4];
		this.owner = owner;

		super( cast(ubyte*)null );

		webView = awe_webcore_create_webview( _width, _height, false );
		urlString = awe_string_create_from_ascii( filePath.toStringz(), filePath.length );

		awe_webview_load_url(webView,
		                     urlString,
		                     awe_string_empty(),
		                     awe_string_empty(),
		                     awe_string_empty());

		// Wait for WebView to finish loading the page
		while(awe_webview_is_loading_page(webView))
			awe_webcore_update();
		
		// Destroy our URL string
		awe_string_destroy( urlString );
	}

	override void update()
	{
		// No webview? No update.
		if ( webView && awe_webview_is_dirty( webView ) )
		{
			const(awe_renderbuffer)* buffer = webView.awe_webview_render();

			// Ensure the buffer exists
			if ( buffer !is null ) {

				buffer.awe_renderbuffer_copy_to( glBuffer.ptr, awe_renderbuffer_get_rowspan( buffer ), 4, false, true );

				updateBuffer( glBuffer.ptr );
			}

		}
	}

	override void shutdown()
	{
		webView.awe_webview_destroy();
	}
}

