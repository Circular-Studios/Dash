/**
 * Handles the creation and life cycle of a web view
 */

module components.userinterface;
import utility.awesomium, components;

class UserInterface
{

}

class AwesomiumView : Component
{
private:
	uint _width, _height;
	awe_webview* webView;
	awe_string* urlString;

public:
	this(uint w, uint h, string fP)
	{
		_width = w;
		_height = h;

		webView = awe_webcore_create_webview(_width, _height, false);
		urlString = awe_string_create_from_ascii(fP.toStringz(), fP.length);

		awe_webview_load_url(webView,
		                     urlString,
		                     awe_string_empty(),
		                     awe_string_empty(),
		                     awe_string_empty());
		
		// Destroy our URL string
		awe_string_destroy(urlString);
	}

	override void shutdown()
	{
		awe_webview_destroy(webView);
	}
}

