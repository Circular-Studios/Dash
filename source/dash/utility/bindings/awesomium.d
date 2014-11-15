module dash.utility.bindings.awesomium;

version( Windows ):

public {
    import core.stdc.stddef;
    version(Windows) {
        import core.sys.windows.windows;
    }
}


extern(C) {
alias wchar wchar16;

alias long int64;

/// WebView instance
struct awe_webview {}
/// JSValue instance
struct awe_jsvalue {}
/// JSArray instance
struct awe_jsarray {}
/// JSObject instance
struct awe_jsobject {}
/// RenderBuffer instance, owned by the WebView
struct awe_renderbuffer {}
/// HeaderDefinition instance
struct awe_header_definition {}
/// ResourceResponse instance
struct awe_resource_response {}
/// ResourceRequest instance
struct awe_resource_request {}
/// UploadElement instance
struct awe_upload_element {}
/// String instance
struct awe_string {}
/// HistoryQueryResult instance
struct awe_history_query_result {}
/// HistoryEntry instance
struct awe_history_entry {}

enum awe_loglevel
{
    AWE_LL_NONE,
    AWE_LL_NORMAL,
    AWE_LL_VERBOSE
}

enum awe_mousebutton
{
    AWE_MB_LEFT,
    AWE_MB_MIDDLE,
    AWE_MB_RIGHT
}

enum awe_url_filtering_mode
{
    AWE_UFM_NONE,
    AWE_UFM_BLACKLIST,
    AWE_UFM_WHITELIST
}

enum awe_webkey_type
{
    AWE_WKT_KEYDOWN,
    AWE_WKT_KEYUP,
    AWE_WKT_CHAR
}

enum awe_webkey_modifiers
{
    /// Whether or not a Shift key is down
    AWE_WKM_SHIFT_KEY       = 1 << 0,
    /// Whether or not a Control key is down
    AWE_WKM_CONTROL_KEY     = 1 << 1,
    /// Whether or not an ALT key is down
    AWE_WKM_ALT_KEY         = 1 << 2,
    /// Whether or not a meta key (Command-key on Mac, Windows-key on Windows) is down
    AWE_WKM_META_KEY        = 1 << 3,
    /// Whether or not the key pressed is on the keypad
    AWE_WKM_IS_KEYPAD       = 1 << 4,
    /// Whether or not the character input is the result of an auto-repeat timer.
    AWE_WKM_IS_AUTOREPEAT   = 1 << 5,
}

enum awe_cursor_type
{
    AWE_CUR_POINTER,
    AWE_CUR_CROSS,
    AWE_CUR_HAND,
    AWE_CUR_IBEAM,
    AWE_CUR_WAIT,
    AWE_CUR_HELP,
    AWE_CUR_EAST_RESIZE,
    AWE_CUR_NORTH_RESIZE,
    AWE_CUR_NORTHEAST_RESIZE,
    AWE_CUR_NORTHWEST_RESIZE,
    AWE_CUR_SOUTH_RESIZE,
    AWE_CUR_SOUTHEAST_RESIZE,
    AWE_CUR_SOUTHWEST_RESIZE,
    AWE_CUR_WEST_RESIZE,
    AWE_CUR_NORTHSOUTH_RESIZE,
    AWE_CUR_EASTWEST_RESIZE,
    AWE_CUR_NORTHEAST_SOUTHWEST_RESIZE,
    AWE_CUR_NORTHWEST_SOUTHEAST_RESIZE,
    AWE_CUR_COLUMN_RESIZE,
    AWE_CUR_ROW_RESIZE,
    AWE_CUR_MIDDLE_PANNING,
    AWE_CUR_EAST_PANNING,
    AWE_CUR_NORTH_PANNING,
    AWE_CUR_NORTHEAST_PANNING,
    AWE_CUR_NORTHWEST_PANNING,
    AWE_CUR_SOUTH_PANNING,
    AWE_CUR_SOUTHEAST_PANNING,
    AWE_CUR_SOUTHWEST_PANNING,
    AWE_CUR_WEST_PANNING,
    AWE_CUR_MOVE,
    AWE_CUR_VERTICAL_TEXT,
    AWE_CUR_CELL,
    AWE_CUR_CONTEXT_MENU,
    AWE_CUR_ALIAS,
    AWE_CUR_PROGRESS,
    AWE_CUR_NO_DROP,
    AWE_CUR_COPY,
    AWE_CUR_NONE,
    AWE_CUR_NOT_ALLOWED,
    AWE_CUR_ZOOM_IN,
    AWE_CUR_ZOOM_OUT,
    AWE_CUR_CUSTOM
}

enum awe_ime_state
{
    AWE_IME_DISABLE = 0,
    AWE_IME_MOVE_WINDOW = 1,
    AWE_IME_COMPLETE_COMPOSITION = 2
}

enum awe_media_type
{
    AWE_MEDIA_TYPE_NONE,
    AWE_MEDIA_TYPE_IMAGE,
    AWE_MEDIA_TYPE_VIDEO,
    AWE_MEDIA_TYPE_AUDIO
}

enum awe_media_state
{
    AWE_MEDIA_STATE_NONE = 0x0,
    AWE_MEDIA_STATE_ERROR = 0x1,
    AWE_MEDIA_STATE_PAUSED = 0x2,
    AWE_MEDIA_STATE_MUTED = 0x4,
    AWE_MEDIA_STATE_LOOP = 0x8,
    AWE_MEDIA_STATE_CAN_SAVE = 0x10,
    AWE_MEDIA_STATE_HAS_AUDIO = 0x20
}

enum awe_can_edit_flags
{
    AWE_CAN_EDIT_NOTHING = 0x0,
    AWE_CAN_UNDO = 0x1,
    AWE_CAN_REDO = 0x2,
    AWE_CAN_CUT = 0x4,
    AWE_CAN_COPY = 0x8,
    AWE_CAN_PASTE = 0x10,
    AWE_CAN_DELETE = 0x20,
    AWE_CAN_SELECT_ALL = 0x40
}

enum awe_dialog_flags
{
    AWE_DIALOG_HAS_OK_BUTTON = 0x1,
    AWE_DIALOG_HAS_CANCEL_BUTTON = 0x2,
    AWE_DIALOG_HAS_PROMPT_FIELD = 0x4,
    AWE_DIALOG_HAS_MESSAGE = 0x8
}

struct awe_webkeyboardevent
{
    awe_webkey_type type;
    int modifiers;
    int virtual_key_code;
    int native_key_code;
    wchar16[4] text = [0, 0, 0, 0];
    wchar16[4] unmodified_text = [0, 0, 0, 0];
    bool is_system_key;
}

struct awe_rect
{
    int x, y, width, height;
}


version(Windows) {
    bool awe_is_child_process(HINSTANCE hInstance);


    int awe_child_process_main(HINSTANCE hInstance);
} else {
    bool awe_is_child_process(int argc, char** argv);

    int awe_child_process_main(int argc, char** argv);
}


/*****************************
 * UTF-16 String Definitions *
 *****************************/

/**
 * Get an instance of an empty string. This is a convenience method to
 * quickly pass an empty string to the C API-- you should not destroy
 * this string yourself.
 */
const(awe_string)* awe_string_empty();

/**
 * Create a string from an ASCII string. You must call awe_string_destroy
 * with the returned instance once you're done using it.
 *
 * @param   str An ASCII string to be copied from.
 *
 * @param   len The length of the string
 */
awe_string* awe_string_create_from_ascii(const(char)* str,
                                         size_t len);

/**
 * Create a string from a Wide string. You must call awe_string_destroy
 * with the returned instance once you're done using it.
 *
 * @param   str A Wide string to be copied from.
 *
 * @param   len The length of the string
 */
awe_string* awe_string_create_from_wide(const(wchar_t)* str,
                                                   size_t len);

/**
 * Create a string from a UTF-8 string. You must call awe_string_destroy
 * with the returned instance once you're done using it.
 *
 * @param   str A UTF-8 string to be copied from.
 *
 * @param   len The length of the string.
 */
awe_string* awe_string_create_from_utf8(const(char)* str,
                                                   size_t len);

/**
 * Create a string from a UTF-16 string. You must call awe_string_destroy
 * with the returned instance once you're done using it.
 *
 * @param   str A UTF-16 string to be copied from.
 *
 * @param   len The length of the string.
 */
awe_string* awe_string_create_from_utf16(const(wchar16)* str,
                                                   size_t len);

/**
 * Destroys a string instance created with one of the above functions.
 *
 * @param   str The instance to destroy.
 */
void awe_string_destroy(awe_string* str);

/**
 * Gets the length of a string.
 *
 * @param   str The string to get the length of.
 *
 * @return  The length of the string.
 */
size_t awe_string_get_length(const(awe_string)* str);

/**
 * Get a pointer to the actual internal UTF-16 bytes of a string.
 *
 * @param   str The string to get the UTF-16 bytes of.
 *
 * @return  A constant pointer to the UTF-16 buffer of the string.
 */
const(wchar16)* awe_string_get_utf16(const(awe_string)* str);

/**
 * Converts a string to a wide string by copying to the destination buffer.
 *
 * @param   str The source string instance
 *
 * @param   dest    The destination buffer to copy to.
 *
 * @param   len The size of the destination buffer.
 *
 * @return  Returns the full size of the string-- you can use this for
 *          pre-allocation purposes: call this method once with a NULL
 *          destination and 0 length to get the size to allocate your
 *          destination buffer, and then call it again to actually
 *          convert the string.
 */
int awe_string_to_wide(const(awe_string)* str,
                                  wchar_t* dest,
                                  size_t len);

/**
 * Converts a string to a UTF-8 string by copying to the destination buffer.
 *
 * @param   str The source string instance
 *
 * @param   dest    The destination buffer to copy to.
 *
 * @param   len The size of the destination buffer.
 *
 * @return  Returns the full size of the string-- you can use this for
 *          pre-allocation purposes: call this method once with a NULL
 *          destination and 0 length to get the size to allocate your
 *          destination buffer, and then call it again to actually
 *          convert the string.
 */
int awe_string_to_utf8(const(awe_string)* str,
                                  char* dest,
                                  size_t len);

/***********************
 * Web Core Functions  *
 ***********************/

/**
 * Instantiates the WebCore singleton with a set of configuration
 * parameters.
 *
 * Here are recommendations for the default parameters:
 * <pre>
 *     enable_plugins              = false
 *     enable_javascript           = true
 *     enable_databases            = false
 *     package_path                = awe_string_empty()
 *     locale_path                 = awe_string_empty()
 *     user_data_path              = awe_string_empty()
 *     plugin_path                 = awe_string_empty()
 *     log_path                    = awe_string_empty()
 *     log_level                   = AWE_LL_NORMAL
 *     forceSingleProcess          = false
 *     childProcessPath            = (empty)
 *     enable_auto_detect_encoding = true
 *     accept_language_override    = awe_string_empty()
 *     default_charset_override    = awe_string_empty()
 *     user_agent_override         = awe_string_empty()
 *     proxy_server                = awe_string_empty()
 *     proxy_config_script         = awe_string_empty()
 *     save_cache_and_cookies      = true
 *     max_cache_size              = 0
 *     disable_same_origin_policy  = false
 *     disable_win_message_pump    = false
 *     custom_css                  = awe_string_empty()
 * </pre>
 */
void awe_webcore_initialize(bool enable_plugins,
                                       bool enable_javascript,
                                       bool enable_databases,
                                       const(awe_string)* package_path,
                                       const(awe_string)* locale_path,
                                       const(awe_string)* user_data_path,
                                       const(awe_string)* plugin_path,
                                       const(awe_string)* log_path,
                                       awe_loglevel log_level,
                                       bool force_single_process,
                                       const(awe_string)* child_process_path,
                                       bool enable_auto_detect_encoding,
                                       const(awe_string)* accept_language_override,
                                       const(awe_string)* default_charset_override,
                                       const(awe_string)* user_agent_override,
                                       const(awe_string)* proxy_server,
                                       const(awe_string)* proxy_config_script,
                                       const(awe_string)* auth_server_whitelist,
                                       bool save_cache_and_cookies,
                                       int max_cache_size,
                                       bool disable_same_origin_policy,
                                       bool disable_win_message_pump,
                                       const(awe_string)* custom_css);

/**
 * Instantiates the WebCore singleton with the default parameters
 * specified in the method above.
 */
void awe_webcore_initialize_default();

/**
 * Destroys the WebCore singleton and destroys any remaining WebViews.
 */
void awe_webcore_shutdown();

/**
 * Sets the base directory.
 *
 * @param   base_dir_path   The absolute path to your base directory.
 *                          The base directory is a location that holds
 *                          all of your local assets. It will be used
 *                          for WebView::loadFile and WebView::loadHTML
 *                          (to resolve relative URLs).
 */
void awe_webcore_set_base_directory(const(awe_string)* base_dir_path);

/**
 * Creates a new WebView.
 *
 * @param   width   The width of the WebView in pixels.
 * @param   height  The height of the WebView in pixels.
 * @param   viewSource  Enable this to view the HTML source of any web-page
 *                      loaded into this WebView. Default is false.
 *
 * @return  Returns a pointer to the created WebView instance. To call methods
 *          on the WebView, see awe_webview_load_url() and related functions.
 */
awe_webview* awe_webcore_create_webview(int width, int height,
                                                   bool view_source);

/**
 * Sets a custom response page to use when a WebView encounters a
 * certain HTML status code from the server (like '404 - File not found').
 *
 * @param   status_code The status code this response page should be
 *                      associated with.
 *                      See <http://en.wikipedia.org/wiki/List_of_HTTP_status_codes>
 *
 * @param   file_path   The local page to load as a response, should be
 *                      a path relative to the base directory.
 */
void awe_webcore_set_custom_response_page(int status_code,
                                                     const(awe_string)* file_path);

/**
 * Updates the WebCore and allows it to conduct various operations such
 * as updating the render buffer of each WebView, destroying any
 * WebViews that are queued for destruction, and invoking any queued
 * callback events.
 */
void awe_webcore_update();

/**
 * Retrieves the base directory.
 *
 * @return  Returns a string instance representing the current
 *          base directory. (You do not need to destroy this instance)
 */
const(awe_string)* awe_webcore_get_base_directory();

/**
 * Returns whether or not plugins are enabled.
 */
bool awe_webcore_are_plugins_enabled();

/**
 * Clear the disk cache and media cache.
 */
void awe_webcore_clear_cache();

/**
 * Clear all cookies.
 */
void awe_webcore_clear_cookies();

/**
 * Sets a cookie for a certain URL.
 *
 * @param   url The URL to set the cookie on.
 *
 * @param   cookie_string   The cookie string, for example:
 *                          <pre> "key1=value1; key2=value2" </pre>
 *
 * @param   is_http_only    Whether or not this cookie is HTTP-only.
 *
 * @param   force_session_cookie    Whether or not to force this as a
 *                              session cookie.
 *
 */
void awe_webcore_set_cookie(const(awe_string)* url,
                                       const(awe_string)* cookie_string,
                                       bool is_http_only,
                                       bool force_session_cookie);

/**
 * Gets all cookies for a certain URL.
 *
 * @param   url The URL whose cookies will be retrieved.
 *
 * @param   exclude_http_only   Whether or not to exclude HTTP-only
 *                              cookies from the result.
 *
 * @return  Returns the cookie string. (You do not need to destroy this string)
 */
const(awe_string)* awe_webcore_get_cookies(const(awe_string)* url,
                                                  bool exclude_http_only);

/**
 * Deletes a certain cookie on a certain URL.
 *
 * @param   url The URL that we will be deleting cookies on.
 *
 * @param   cookie_name The name of the cookie that will be deleted.
 */
void awe_webcore_delete_cookie(const(awe_string)* url,
                                          const(awe_string)* cookie_name);


/**
 * Set whether or not the printer dialog should be suppressed or not.
 * Set this to "true" to hide printer dialogs and print immediately
 * using the OS's default printer when WebView::print is called.
 * Default is "false" if you never call this.
 *
 * @param   suppress    Whether or not the printer dialog should be
 *                      suppressed.
 */
void awe_webcore_set_suppress_printer_dialog(bool suppress);

/**
 * Query the on-disk history database.
 *
 * @param   full_text_query All results returned should match the
 *                          specified text (either in the page title or
 *                          in the actual text of the page itself).
 *                          Specify an empty string to match anything.
 *
 * @param   num_days_ago    Limit results to a specified number of days ago.
 *
 * @param   max_count   Limit results to a maximum count. Specify 0 to
 *                      use no limit.
 *
 * @note    You must enable "SaveCacheAndCookies" (see awe_webcore_initialize) for
 *          this method to work (otherwise no results will be returned).
 *
 * @return  Returns an instance of awe_history_query_result containing the results
 *          of the query. You must call awe_history_query_result_destroy once
 *          you are finished using the instance.
 */
awe_history_query_result* awe_webcore_query_history(const(awe_string)* full_text_query,
                                          int num_days_ago, int max_count);


/***********************
 * Web View Functions  *
 ***********************/

/**
 * Queue a WebView for destruction by the WebCore.
 *
 * @param   webview     The WebView instance.
 *
 */
void awe_webview_destroy(awe_webview* webview);

/**
 * Loads a URL into the WebView asynchronously.
 *
 * @param   webview     The WebView instance.
 *
 * @param   url The URL to load.
 *
 * @param   frame_name  The name of the frame to load the URL
 *                      in; leave this blank to load in the main frame.
 *
 * @param   username    If the URL requires authentication, the username
 *                      to authorize as, otherwise just pass an empty string.
 *
 * @param   password    If the URL requires authentication, the password
 *                      to use, otherwise just pass an empty string.
 */
void awe_webview_load_url(awe_webview* webview,
                                     const(awe_string)* url,
                                     const(awe_string)* frame_name,
                                     const(awe_string)* username,
                                     const(awe_string)* password);

/**
 * Loads a string of HTML into the WebView asynchronously.
 *
 * @param   webview     The WebView instance.
 *
 * @param   html    The HTML string (ASCII) to load.
 *
 * @param   frame_name  The name of the frame to load the HTML
 *                      in; leave this blank to load in the main frame.
 */
void awe_webview_load_html(awe_webview* webview,
                                      const(awe_string)* html,
                                      const(awe_string)* frame_name);

/**
 * Loads a local file into the WebView asynchronously.
 *
 * @param   webview     The WebView instance.
 *
 * @param   file    The file to load.
 *
 * @param   frame_name  The name of the frame to load the file
 *                      in; leave this blank to load in the main frame.
 *
 * @note    The file should exist within the base directory.
 */
void awe_webview_load_file(awe_webview* webview,
                                      const(awe_string)* file,
                                      const(awe_string)* frame_name);

awe_string* awe_webview_get_url(awe_webview* webview);

/**
 * Navigates back/forward in history via a relative offset.
 *
 * @param   webview     The WebView instance.
 *
 * @param   offset  The relative offset in history to navigate to.
 */
void awe_webview_go_to_history_offset(awe_webview* webview,
                                                 int offset);

/// Get the number of steps back in history we can go.
int awe_webview_get_history_back_count(awe_webview* webview);

/// Get the number of steps forward in history we can go.
int awe_webview_get_history_forward_count(awe_webview* webview);

/**
 * Stops the current navigation.
 */
void awe_webview_stop(awe_webview* webview);

/**
 * Reloads the current page.
 */
void awe_webview_reload(awe_webview* webview);

/**
 * Executes a string of Javascript in the context of the current page
 * asynchronously.
 *
 * @param   javascript  The string of Javascript to execute.
 *
 * @param   frame_name  The name of the frame to execute in;
 *                      pass an empty string to execute in the main frame.
 */
void awe_webview_execute_javascript(awe_webview* webview,
                                               const(awe_string)* javascript,
                                               const(awe_string)* frame_name);

/**
 * Executes a string of Javascript in the context of the current page
 * asynchronously with a result.
 *
 * @param   javascript  The string of Javascript to execute.
 *
 * @param   frame_name  The name of the frame to execute in;
 *                      pass an empty string to execute in the main frame.
 *
 * @param   timeout_ms  The maximum amount of time (in milliseconds) to wait
 *                      for a result. Pass 0 to use no timeout. (If no result
 *                      is obtained, or the timeout is reached, this function
 *                      will return a jsvalue with type "null")
 *
 * @return  Returns an awe_jsvalue instance. You must call awe_jsvalue_destroy
 *          on this instance when you're done using it.
 */
awe_jsvalue* awe_webview_execute_javascript_with_result(
                                                    awe_webview* webview,
                                                    const(awe_string)* javascript,
                                                    const(awe_string)* frame_name,
                                                    int timeout_ms);
/**
 * Call a certain function defined in Javascript directly.
 *
 * @param   object  The name of the object that contains the function,
 *                  pass an empty string if the function is defined in
 *                  the global scope.
 *
 * @param   function    The name of the function.
 *
 * @param   args    The arguments to pass to the function.
 *
 * @param   frame_name  The name of the frame to execute in;
 *                      leave this blank to execute in the main frame.
 */
void awe_webview_call_javascript_function(awe_webview* webview,
                                                     const(awe_string)* object,
                                                     const(awe_string)* function_,
                                                     const(awe_jsarray)* arguments,
                                                     const(awe_string)* frame_name);

/**
 * Creates a new global Javascript object that will persist throughout
 * the lifetime of this WebView. This object is managed directly by
 * Awesomium and so you can modify its properties and bind callback
 * functions via awe_webview_set_object_property() and
 * awe_webview_set_object_callback(), respectively.
 *
 * @param   objectName  The name of the object.
 */
void awe_webview_create_object(awe_webview* webview,
                                          const(awe_string)* object_name);

/**
 * Destroys a Javascript object previously created by
 * awe_webview_create_object
 *
 * @param   object_name The name of the object to destroy.
 */
void awe_webview_destroy_object(awe_webview* webview,
                                           const(awe_string)* object_name);

/**
 * Sets a property of a Javascript object previously created by
 * awe_webview_create_object().
 *
 * @param   object_name The name of the Javascript object.
 *
 * @param   property_name   The name of the property.
 *
 * @param   value   The javascript-value of the property.
 */
void awe_webview_set_object_property(awe_webview* webview,
                                                const(awe_string)* object_name,
                                                const(awe_string)* property_name,
                                                const(awe_jsvalue)* value);

/**
 * Sets a callback function of a Javascript object previously created
 * by awe_webview_create_object(). This is very useful for passing events
 * from Javascript to C. To receive notification of the callback, please
 * see awe_webview_set_callback_js_callback().
 *
 * @param   object_name The name of the Javascript object.
 *
 * @param   callback_name   The name of the callback function.
 */
void awe_webview_set_object_callback(awe_webview* webview,
                                                const(awe_string)* object_name,
                                                const(awe_string)* callback_name);

/**
 * Returns whether or not a page is currently loading in the WebView.
 *
 * @return  If a page is loading, returns true, otherwise returns false.
 */
bool awe_webview_is_loading_page(awe_webview* webview);

/**
 * Returns whether or not the WebView is dirty and needs to be
 * re-rendered via awe_webview_render.
 *
 * @return  If the WebView is dirty, returns true, otherwise returns
 *          false.
 */
bool awe_webview_is_dirty(awe_webview* webview);

/**
 * Returns the bounds of the area that has changed since the last call
 * to awe_webview_render.
 *
 * @return  The bounds of the dirty area.
 */
awe_rect awe_webview_get_dirty_bounds(awe_webview* webview);

/**
 * Renders this WebView into an offscreen render buffer and clears the
 * dirty state.
 *
 * @return  A pointer to the internal render buffer instance that was used to
 *           render this WebView. This value may change between renders and
 *           may return NULL if the WebView has crashed.
 */
const(awe_renderbuffer)* awe_webview_render(awe_webview* webview);

/**
 * All rendering is actually done asynchronously in a separate process
 * and so the page is usually continuously rendering even if you never
 * call awe_webview_render. Call this to temporarily pause rendering.
 */
void awe_webview_pause_rendering(awe_webview* webview);

/**
 * Resume rendering after all call to awe_webview_pause_rendering.
 */
void awe_webview_resume_rendering(awe_webview* webview);

/**
 * Injects a mouse-move event in local coordinates.
 *
 * @param   x   The absolute x-coordinate of the mouse (localized to
 *              the WebView).
 *
 * @param   y   The absolute y-coordinate of the mouse (localized to
 *              the WebView).
 */
void awe_webview_inject_mouse_move(awe_webview* webview,
                                              int x,
                                              int y);

/**
 * Injects a mouse-down event.
 *
 * @param   button  The button that was pressed.
 */
void awe_webview_inject_mouse_down(awe_webview* webview,
                                              awe_mousebutton button);

/**
 * Injects a mouse-up event.
 *
 * @param   button  The button that was released.
 */
void awe_webview_inject_mouse_up(awe_webview* webview,
                                            awe_mousebutton button);

/**
 * Injects a mouse-wheel event.
 *
 * @param   scrollAmountVert    The relative amount of pixels to scroll vertically.
 *
 * @param   scrollAmountHorz    The relative amount of pixels to scroll horizontally.
 */
void awe_webview_inject_mouse_wheel(awe_webview* webview,
                                               int scroll_amount_vert,
                                               int scroll_amount_horz);

/**
 * Injects a keyboard event. You'll need to initialize the members of
 * awe_webkeyboardevent yourself.
 *
 * @param   keyboardEvent   The keyboard event to inject.
 */
void awe_webview_inject_keyboard_event(awe_webview* webview,
                                                  awe_webkeyboardevent key_event);

version(Windows) {
    /**
    * Injects a native Windows keyboard event.
    *
    * @param    msg The msg parameter.
    * @param    wparam  The wparam parameter.
    * @param    lparam  The lparam parameter.
    */
    void awe_webview_inject_keyboard_event_win(awe_webview* webview,
                                                        UINT msg,
                                                        WPARAM wparam,
                                                        LPARAM lparam);
}

/**
 * Invokes a 'cut' action using the system clipboard.
 */
void awe_webview_cut(awe_webview* webview);

/**
 * Invokes a 'copy' action using the system clipboard.
 */
void awe_webview_copy(awe_webview* webview);

/**
 * Invokes a 'paste' action using the system clipboard.
 */
void awe_webview_paste(awe_webview* webview);

/**
 * Selects all items on the current page.
 */
void awe_webview_select_all(awe_webview* webview);

/// Copies an image on the page to the system clipboard.
void awe_webview_copy_image_at(awe_webview* webview,
                                          int x,
                                          int y);

/**
 * Zooms the page a specified percent.
 *
 * @param   zoom_percent    The percent of the page to zoom to. Valid range
 *                          is from 10% to 500%.
 */
void awe_webview_set_zoom(awe_webview* webview,
                                     int zoom_percent);

/**
 * Resets the zoom level.
 */
void awe_webview_reset_zoom(awe_webview* webview);

/// Gets the current zoom level.
int awe_webview_get_zoom(awe_webview* webview);

/// Gets the zoom level for a specific hostname.
int awe_webview_get_zoom_for_host(awe_webview* webview,
                                             const(awe_string)* host);

/**
 * Resizes this WebView to certain dimensions.
 *
 * @param   width   The width in pixels to resize to.
 *
 * @param   height  The height in pixels to resize to.
 *
 * @param   wait_for_repaint    Whether or not to wait for the WebView
 *                          to finish repainting.
 *
 * @param   repaint_timeout_ms  The maximum amount of time to wait
 *                              for a repaint, in milliseconds.
 *
 * @return  Returns true if the resize was successful. This operation
 *          can fail if there is another resize already pending (see
 *          awe_webview_is_resizing) or if the repaint timeout was exceeded.
 */
bool awe_webview_resize(awe_webview* webview,
                                   int width,
                                   int height,
                                   bool wait_for_repaint,
                                   int repaint_timeout_ms);

/**
* Checks whether or not there is a resize operation pending.
*
* @return   Returns true if we are waiting for the WebView process to
*           return acknowledgement of a pending resize operation.
*/
bool awe_webview_is_resizing(awe_webview* webview);

/**
 * Notifies the current page that it has lost focus.
 */
void awe_webview_unfocus(awe_webview* webview);

/**
 * Notifies the current page that is has gained focus. You will need
 * to call this to gain textbox focus, among other things. (If you
 * fail to ever see a blinking caret when typing text, this is why).
 */
void awe_webview_focus(awe_webview* webview);

/**
 * Sets whether or not pages should be rendered with transparency
 * preserved. (ex, for pages with style="background-color:transparent")
 *
 * @param   is_transparent  Whether or not this WebView is transparent.
 */
void awe_webview_set_transparent(awe_webview* webview,
                                            bool is_transparent);

bool awe_webview_is_transparent(awe_webview* webview);

/**
 * Sets the current URL Filtering Mode (default is AWE_UFM_NONE).
 * See awe_url_filtering_mode for more information on the modes.
 *
 * @param   mode    The URL filtering mode to use.
 */
void awe_webview_set_url_filtering_mode(awe_webview* webview,
                                                   awe_url_filtering_mode mode);

/**
 * Adds a new URL Filter rule.
 *
 * @param   filter  A string with optional wildcards that describes a
 *                  certain URL.
 *
 * @note        For example, to match all URLs from the domain
 *              "google.com", your filter string might be:
 *                  http://google.com/*
 *
 * @note        You may also use the "local://" scheme prefix to
 *              describe the URL to the base directory (set via
 *              awe_webcore_set_base_directory).
 */
void awe_webview_add_url_filter(awe_webview* webview,
                                           const(awe_string)* filter);

/**
 * Clears all URL Filter rules.
 */
void awe_webview_clear_all_url_filters(awe_webview* webview);

/**
 * Defines a new Header Definition or updates it if it already exists.
 *
 * @param   name    The unique name of the Header Definition; this is
 *                  used to refer to it later in
 *                  awe_webview_add_header_rewrite_rule and
 *                  related methods.
 *
 * @param   num_fields  The number of fields in the header.
 *
 * @param   field_names An array of strings representing the field names
 *
 * @param   field_vales An array of strings representing the field values
 */
void awe_webview_set_header_definition(awe_webview* webview,
                                            const(awe_string)* name,
                                            size_t num_fields,
                                            const(awe_string*)* field_names,
                                            const(awe_string*)* field_values);

/**
 * Adds a new a header re-write rule. All requests whose URL matches the
 * specified rule will have its  HTTP headers re-written with the
 * specified header definition before sending it to the server.
 *
 * @param   rule    A string with optional wildcards (*, ?) that
 *                  matches the URL(s) that will have its headers
 *                  re-written with the specified header definition.
 *
 * @param   name    The name of the header definition (specified in
 *                  awe_webview_set_header_definition).
 *
 * @note        The case where a URL is matched by multiple rules is
 *              unsupported, only the first match will be used.
 */
void awe_webview_add_header_rewrite_rule(awe_webview* webview,
                                                    const(awe_string)* rule,
                                                    const(awe_string)* name);

/**
 * Removes a header re-write rule from this WebView.
 *
 * @param   rule    The rule to remove (should match the string
 *                  specified in awe_webview_add_header_rewrite_rule exactly).
 */
void awe_webview_remove_header_rewrite_rule(awe_webview* webview,
                                                       const(awe_string)* rule);

/**
 * Removes all header re-write rules that are using a certain header
 * definition.
 *
 * @param   name    The name of the header definition (specified in
 *                  awe_webview_set_header_definition). If you specify an
 *                  empty string, this will remove ALL header re-write rules.
 */
void awe_webview_remove_header_rewrite_rules_by_definition_name(
                                                        awe_webview* webview,
                                                        const(awe_string)* name);

/**
 * This should be called as a response to the request file chooser callback.
 *
 * @param   file_path   The full path to the file that was chosen.
 */
void awe_webview_choose_file(awe_webview* webview,
                                        const(awe_string)* file_path);

/**
 * Print the current page. To suppress the printer selection dialog and
 * print immediately using the operating system's defaults, see
 * awe_webcore_set_suppress_printer_dialog.
 */
void awe_webview_print(awe_webview* webview);

/**
 * Request the page dimensions and scroll position of the page. You can
 * retrieve the response via the get scroll data callback.
 *
 * @param   frame_name  The frame's scroll data to retrieve. Leave blank
 *                      to get the main frame's scroll data.
 */
void awe_webview_request_scroll_data(awe_webview* webview,
                                                const(awe_string)* frame_name);

/**
 * Start finding a certain string on the current web-page. All matches
 * of the string will be highlighted on the page and you can jump
 * to different instances of the string by using the 'findNext'
 * parameter. To get actual stats about a certain query, please see
 * awe_webview_set_callback_get_find_results.
 *
 * @param   request_id  A unique numeric ID for each search. You will
 *                      need to generate one yourself for each unique
 *                      search-- please note that you should use the
 *                      same request_id if you wish to iterate through
 *                      all the search results using the 'findNext'
 *                      parameter.
 *
 * @param   search_string   The string to search for.
 *
 * @param   forward     Whether or not we should search forward, down
 *                      the page.
 *
 * @param   case_sensitive  Whether or not this search is case-sensitive.
 *
 * @param   find_next   Whether or not we should jump to the next
 *                      instance of a search string (you should use
 *                      the same request_id as a previously-successful
 *                      search).
 */
void awe_webview_find(awe_webview* webview,
                                 int request_id,
                                 const(awe_string)* search_string,
                                 bool forward,
                                 bool case_sensitive,
                                 bool find_next);


/**
 * Stop finding. This will un-highlight all matches of a previous
 * call to awe_webview_find.
 *
 * @param   clear_selection Whether or not we should also deselect
 *                          the currently-selected string instance.
 */
void awe_webview_stop_find(awe_webview* webview,
                                      bool clear_selection);

/**
 * Attempt automatic translation of the current page via Google
 * Translate. All language codes are ISO 639-2.
 *
 * @param   source_language The language to translate from
 *                              (for ex. "en" for English)
 *
 * @param   target_language The language to translate to
 *                              (for ex. "fr" for French)
 */
void awe_webview_translate_page(awe_webview* webview,
                                           const(awe_string)* source_language,
                                           const(awe_string)* target_language);

/**
 * Call this method to let the WebView know you will be passing
 * text input via IME and will need to be notified of any
 * IME-related events (caret position, user unfocusing textbox, etc.)
 * Please see awe_webview_set_callback_update_ime
 */
void awe_webview_activate_ime(awe_webview* webview,
                                         bool activate);

/**
 * Update the current IME text composition.
 *
 * @param   inputString The string generated by your IME.
 * @param   cursorPos   The current cursor position in your IME composition.
 * @param   targetStart The position of the beginning of the selection.
 * @param   targetEnd   The position of the end of the selection.
 */
void awe_webview_set_ime_composition(awe_webview* webview,
                                                const(awe_string)* input_string,
                                                int cursor_pos,
                                                int target_start,
                                                int target_end);

/**
 * Confirm a current IME text composition.
 *
 * @param   inputString The string generated by your IME.
 */
void awe_webview_confirm_ime_composition(awe_webview* webview,
                                                    const(awe_string)* input_string);

/**
 * Cancel a current IME text composition.
 */
void awe_webview_cancel_ime_composition(awe_webview* webview);

/**
 * Respond to the "request login" callback with some user-supplied
 * credentials.
 *
 * @param   request_id  The unique ID of the request.
 *
 * @param   username    The username supplied by the user.
 *
 * @param   password    The password supplied by the user.
 */
void awe_webview_login(awe_webview* webview,
                                  int request_id,
                                  const(awe_string)* username,
                                  const(awe_string)* password);

/**
 * Respond to the "request login" callback by telling the
 * server that the user cancelled the authentication request.
 *
 * @param   request_id  The unique ID of the request.
 */
void awe_webview_cancel_login(awe_webview* webview,
                                         int request_id);

/**
 * Respond to the "show javascript dialog" callback.
 *
 * @param   request_id  The unique ID of the dialog request.
 *
 * @param   was_cancelled   Whether or not the dialog was cancelled/ignored.
 *
 * @param   prompt_text If the dialog had a prompt, you should pass whatever
 *                      text the user entered into the textbox via this parameter.
 */
void awe_webview_close_javascript_dialog(awe_webview* webview,
                                                    int request_id,
                                                    bool was_cancelled,
                                                    const(awe_string)* prompt_text);

/**
 * Assign a callback function to be notified when a WebView begins navigation
 * to a certain URL.
 *
 * @param   webview     The WebView instance.
 *
 * @param   callback    A function pointer to the callback.
 */
void awe_webview_set_callback_begin_navigation(
                            awe_webview* webview,
                            void function(awe_webview* caller,
                                             const(awe_string)* url,
                                             const(awe_string)* frame_name) callback);

/**
 * Assign a callback function to be notified when a WebView begins to actually
 * receive data from a server.
 *
 * @param   webview     The WebView instance.
 *
 * @param   callback    A function pointer to the callback.
 */
void awe_webview_set_callback_begin_loading(
                            awe_webview* webview,
                            void function(awe_webview* caller,
                                             const(awe_string)* url,
                                             const(awe_string)* frame_name,
                                             int status_code,
                                             const(awe_string)* mime_type) callback);

/**
 * Assign a callback function to be notified when a WebView has finished
 * all loads.
 *
 * @param   webview     The WebView instance.
 *
 * @param   callback    A function pointer to the callback.
 */
void awe_webview_set_callback_finish_loading(
                            awe_webview* webview,
                            void function(awe_webview* caller) callback);

/**
 * Assign a callback function to be notified when a Javascript object callback
 * has been invoked on a page.
 *
 * @param   webview     The WebView instance.
 *
 * @param   callback    A function pointer to the callback.
 */
void awe_webview_set_callback_js_callback(
                            awe_webview* webview,
                            void function(awe_webview* caller,
                                             const(awe_string)* object_name,
                                             const(awe_string)* callback_name,
                                             const(awe_jsarray)* arguments) callback);

/**
 * Assign a callback function to be notified when a page title is received.
 *
 * @param   webview     The WebView instance.
 *
 * @param   callback    A function pointer to the callback.
 */
void awe_webview_set_callback_receive_title(
                            awe_webview* webview,
                            void function(awe_webview* caller,
                                             const(awe_string)* title,
                                             const(awe_string)* frame_name) callback);

/**
 * Assign a callback function to be notified when a tooltip has changed state.
 *
 * @param   webview     The WebView instance.
 *
 * @param   callback    A function pointer to the callback.
 */
void awe_webview_set_callback_change_tooltip(
                            awe_webview* webview,
                            void function(awe_webview* caller,
                                             const(awe_string)* tooltip) callback);

/**
 * Assign a callback function to be notified when a cursor has changed state.
 *
 * @param   webview     The WebView instance.
 *
 * @param   callback    A function pointer to the callback.
 */
void awe_webview_set_callback_change_cursor(
                            awe_webview* webview,
                            void function(awe_webview* caller,
                                             awe_cursor_type cursor) callback);

/**
 * Assign a callback function to be notified when keyboard focus has changed.
 *
 * @param   webview     The WebView instance.
 *
 * @param   callback    A function pointer to the callback.
 */
void awe_webview_set_callback_change_keyboard_focus(
                            awe_webview* webview,
                            void function(awe_webview* caller,
                                             bool is_focused) callback);

/**
 * Assign a callback function to be notified when the target URL has changed.
 * This is usually the result of hovering over a link on the page.
 *
 * @param   webview     The WebView instance.
 *
 * @param   callback    A function pointer to the callback.
 */
void awe_webview_set_callback_change_target_url(
                            awe_webview* webview,
                            void function(awe_webview* caller,
                                             const(awe_string)* url) callback);

/**
 * Assign a callback function to be notified when an external link is attempted
 * to be opened. An external link is any link that normally opens in a new
 * window in a standard browser (for example, links with target="_blank",
 * calls to window.open(url), and URL open events from Flash plugins).
 *
 * @param   webview     The WebView instance.
 *
 * @param   callback    A function pointer to the callback.
 */
void awe_webview_set_callback_open_external_link(
                            awe_webview* webview,
                            void function(awe_webview* caller,
                                             const(awe_string)* url,
                                             const(awe_string)* source) callback);

/**
 * Assign a callback function to be notified when a page requests for a certain
 * URL to be downloaded by the user.
 *
 * @param   webview     The WebView instance.
 *
 * @param   callback    A function pointer to the callback.
 */
void awe_webview_set_callback_request_download(
                            awe_webview* webview,
                            void function(awe_webview* caller,
                                             const(awe_string)* download) callback);

/**
 * Assign a callback function to be notified when the renderer for a certain
 * WebView (which is isolated in a separate process) crashes unexpectedly.
 *
 * @param   webview     The WebView instance.
 *
 * @param   callback    A function pointer to the callback.
 */
void awe_webview_set_callback_web_view_crashed(
                            awe_webview* webview,
                            void function(awe_webview* caller) callback);

/**
 * Assign a callback function to be notified when when the renderer for a
 * certain plugin (usually Flash, which is isolated in a separate process)
 * crashes unexpectedly.
 *
 * @param   webview     The WebView instance.
 *
 * @param   callback    A function pointer to the callback.
 */
void awe_webview_set_callback_plugin_crashed(
                            awe_webview* webview,
                            void function(awe_webview* caller,
                                             const(awe_string)* plugin_name) callback);

/**
 * Assign a callback function to be notified when the page requests for the
 * containing window to be moved to a certain location on the screen.
 *
 * @param   webview     The WebView instance.
 *
 * @param   callback    A function pointer to the callback.
 */
void awe_webview_set_callback_request_move(
                            awe_webview* webview,
                            void function(awe_webview* caller,
                                             int x,
                                             int y) callback);

/**
 * Assign a callback function to be notified when the contents of the page has finished
 * loading. This occurs at the end of most page loads.
 *
 * @param   webview     The WebView instance.
 *
 * @param   callback    A function pointer to the callback.
 */
void awe_webview_set_callback_get_page_contents(
                            awe_webview* webview,
                            void function(awe_webview* caller,
                                             const(awe_string)* url,
                                             const(awe_string)* contents) callback);

/**
 * Assign a callback function to be notified once the DOM (Document Object
 * Model) for a page is ready. This is very useful for executing Javascript
 * on a page before its content has finished loading.
 *
 * @param   webview     The WebView instance.
 *
 * @param   callback    A function pointer to the callback.
 */
void awe_webview_set_callback_dom_ready(
                            awe_webview* webview,
                            void function(awe_webview* caller) callback);

/**
 * Assign a callback function to be notified whenever a page requests a file
 * chooser dialog to be displayed (usually the result of an "input" element
 * with type "file" being clicked by a user). You will need to display your
 * own dialog (it does not have to be modal, this request does not block).
 * Once a file has been chosen by the user, awe_webview_choose_file or
 * awe_webview_choose_multiple_files should be called.
 *
 * @param   webview     The WebView instance.
 *
 * @param   callback    A function pointer to the callback.
 */
void awe_webview_set_callback_request_file_chooser(
                            awe_webview* webview,
                            void function(awe_webview* caller,
                                             bool select_multiple_files,
                                             const(awe_string)* title,
                                             const(awe_string)* default_path) callback);

/**
 * Assign a callback function to be notified of a response to
 * awe_webview_request_scroll_data.
 *
 * @param   webview     The WebView instance.
 *
 * @param   callback    A function pointer to the callback.
 */
void awe_webview_set_callback_get_scroll_data(
                            awe_webview* webview,
                            void function(awe_webview* caller,
                                             int contentWidth,
                                             int contentHeight,
                                             int preferredWidth,
                                             int scrollX,
                                             int scrollY) callback);

/**
 * Assign a callback function to be notified of any Javascript
 * console messages. (Usually Javascript errors encountered in scripts)
 *
 * @param   webview     The WebView instance
 *
 * @param   callback    A function pointer to the callback.
 */
void awe_webview_set_callback_js_console_message(
                            awe_webview* webview,
                            void function(awe_webview* caller,
                                           const(awe_string)* message,
                                           int line_number,
                                           const(awe_string)* source) callback);

/**
 * Assign a callback function to be notified whenever we receive
 * results back from an in-page find operation (awe_webview_find).
 *
 * @param   webview     The WebView instance
 *
 * @param   callback    A function pointer to the callback.
 */
void awe_webview_set_callback_get_find_results(
                            awe_webview* webview,
                            void function(awe_webview* caller,
                                           int request_id,
                                           int num_matches,
                                           awe_rect selection,
                                           int cur_match,
                                           bool finalUpdate) callback);

/**
 * Assign a callback function to be notified whenever the user does
 * something that may change the position or visiblity of the IME Widget.
 * This callback is only active when IME is activated (please
 * see awe_webview_activate_ime).
 *
 * @param   webview     The WebView instance
 *
 * @param   callback    A function pointer to the callback.
 */
void awe_webview_set_callback_update_ime(
                            awe_webview* webview,
                            void function(awe_webview* caller,
                                           awe_ime_state state,
                                           awe_rect caret_rect) callback);

/**
 * Assign a callback function to be notified whenever the page requests
 * a context menu to be shown (usually the result of a user right-clicking
 * somewhere on the page). It is your responsiblity to display a menu for
 * the user to select an appropriate action.
 *
 * @param   webview The WebView instance
 *
 * @param   callback    A function pointer to the callback.
 */
void awe_webview_set_callback_show_context_menu(
                            awe_webview* webview,
                            void function(awe_webview* caller,
                                       int mouse_x,
                                       int mouse_y,
                                       awe_media_type type,
                                       int media_state,
                                       const(awe_string)* link_url,
                                       const(awe_string)* src_url,
                                       const(awe_string)* page_url,
                                       const(awe_string)* frame_url,
                                       const(awe_string)* selection_text,
                                       bool is_editable,
                                       int edit_flags) callback);

/**
 * Assign a callback function to be notified whenever a page requests
 * authentication from the user (ex, Basic HTTP Auth, NTLM Auth, etc.).
 * See awe_webview_login and awe_webview_cancel_login
 *
 * @param   webview The WebView instance
 *
 * @param   callback A function pointer to the callback.
 */
void awe_webview_set_callback_request_login(
                            awe_webview* webview,
                            void function(awe_webview* caller,
                                   int request_id,
                                   const(awe_string)* request_url,
                                   bool is_proxy,
                                   const(awe_string)* host_and_port,
                                   const(awe_string)* scheme,
                                   const(awe_string)* realm) callback);

/**
 * Assign a callback function to be notified whenever the history state
 * has changed. (eg, the state of thie back/forward buttons should be
 * updated)
 *
 * @param   webview The WebView instance
 *
 * @param   callback    A function pointer to the callback.
 */
void awe_webview_set_callback_change_history(
                            awe_webview* webview,
                            void function(awe_webview* caller,
                                    int back_count,
                                    int forward_count) callback);

/**
 * Assign a callback function to be notified whenever a WebView has
 * finished resizing to a certain size (and has finished repainting
 * the RenderBuffer).
 *
 * @param   webview The WebView instance
 *
 * @param   callback    A function pointer to the callback.
 */
void awe_webview_set_callback_finish_resize(
                            awe_webview* webview,
                            void function(awe_webview* caller,
                                   int width,
                                   int height) callback);

/**
 * Assign a callback function to be notified whenever a WebView
 * requests that a certain Javascript dialog be shown (eg, alert,
 * confirm, prompt). See awe_webview_close_javascript_dialog for
 * more information.
 *
 * @param   webview The WebView instance
 *
 * @param   callback    A function pointer to the callback.
 */
void awe_webview_set_callback_show_javascript_dialog(
                            awe_webview* webview,
                            void function(awe_webview* caller,
                                            int request_id,
                                            int dialog_flags,
                                            const(awe_string)* message,
                                            const(awe_string)* default_prompt,
                                            const(awe_string)* frame_url) callback);

/***********************
 * JS Value Functions  *
 ***********************/

enum awe_jsvalue_type
{
    JSVALUE_TYPE_NULL,
    JSVALUE_TYPE_BOOLEAN,
    JSVALUE_TYPE_INTEGER,
    JSVALUE_TYPE_DOUBLE,
    JSVALUE_TYPE_STRING,
    JSVALUE_TYPE_OBJECT,
    JSVALUE_TYPE_ARRAY
}

/**
 * Create a JSValue instance initialized as a null type. You must call
 * awe_jsvalue_destroy with the returned instance once you're done using it.
 */
awe_jsvalue* awe_jsvalue_create_null_value();

/**
 * Create a JSValue instance initialized with a boolean type. You must call
 * awe_jsvalue_destroy with the returned instance once you're done using it.
 *
 * @param   value   The initial value
 */
awe_jsvalue* awe_jsvalue_create_bool_value(bool value);

/**
 * Create a JSValue instance initialized with an integer type. You must call
 * awe_jsvalue_destroy with the returned instance once you're done using it.
 *
 * @param   value   The initial value
 */
awe_jsvalue* awe_jsvalue_create_integer_value(int value);

/**
 * Create a JSValue instance initialized with a double type. You must call
 * awe_jsvalue_destroy with the returned instance once you're done using it.
 *
 * @param   value   The initial value
 */
awe_jsvalue* awe_jsvalue_create_double_value(double value);

/**
 * Create a JSValue instance initialized with a string type. You must call
 * awe_jsvalue_destroy with the returned instance once you're done using it.
 *
 * @param   value   The initial value
 */
awe_jsvalue* awe_jsvalue_create_string_value(const(awe_string)* value);

/**
 * Create a JSValue instance initialized with an object type. You must call
 * awe_jsvalue_destroy with the returned instance once you're done using it.
 *
 * @param   value   The initial value
 */
awe_jsvalue* awe_jsvalue_create_object_value(const(awe_jsobject)* value);

/**
 * Create a JSValue instance initialized with an array type. You must call
 * awe_jsvalue_destroy with the returned instance once you're done using it.
 *
 * @param   value   The initial value
 */
awe_jsvalue* awe_jsvalue_create_array_value(const(awe_jsarray)* value);

/**
 * Destroys a JSValue instance.
 *
 * @param   jsvalue The JSValue instance.
 */
void awe_jsvalue_destroy(awe_jsvalue* jsvalue);

/**
 * Get the type of a JSValue.
 *
 * @param   jsvalue The JSValue instance.
 *
 * @return  Returns the type of the JSValue (see enum awe_jsvalue_type)
 */
awe_jsvalue_type awe_jsvalue_get_type(const(awe_jsvalue)* jsvalue);

/**
 * Get the value as a string.
 *
 * @param   jsvalue The JSValue instance.
 *
 * @return  Returns a string instance. You'll need to call awe_string_destroy
 *          with this instance when you're done using it.
 */
awe_string* awe_jsvalue_to_string(const(awe_jsvalue)* jsvalue);

/// Returns this value as an integer.
int awe_jsvalue_to_integer(const(awe_jsvalue)* jsvalue);

/// Returns this value as an double.
double awe_jsvalue_to_double(const(awe_jsvalue)* jsvalue);

/// Returns this value as an boolean.
bool awe_jsvalue_to_boolean(const(awe_jsvalue)* jsvalue);

/// Returns this value as an array. Will throw an exception if not an array.
const(awe_jsarray)* awe_jsvalue_get_array(const(awe_jsvalue)* jsvalue);

/// Returns this value as an object. Will throw an exception if not an object.
const(awe_jsobject)* awe_jsvalue_get_object(const(awe_jsvalue)* jsvalue);

/****************************
 * JS Value Array Functions *
 ****************************/

/**
 * Create a JSValue Array.
 *
 * @param   jsvalue_array   An array of JSValue instances to be copied from.
 * @param   length      Length of the array.
 */
awe_jsarray* awe_jsarray_create(const(awe_jsvalue*)* jsvalue_array,
                                           size_t length);

/**
 * Destroys a JSValue Array created with awe_jsarray_create.
 */
void awe_jsarray_destroy(awe_jsarray* jsarray);

/**
 * Get the size of a JSValue Array.
 */
size_t awe_jsarray_get_size(const(awe_jsarray)* jsarray);

/**
 * Get a specific element of a JSValue Array. The Array retains ownership
 * of the returned JSValue instance (you do not need to destroy it).
 */
const(awe_jsvalue)* awe_jsarray_get_element(const(awe_jsarray)* jsarray,
                                                       size_t index);

/*****************************
 * JS Value Object Functions *
 *****************************/

/**
 * Creates a JSValue Object.
 */
awe_jsobject* awe_jsobject_create();

/**
 * Destroys a JSValue Object created with awe_jsobject_create
 */
void awe_jsobject_destroy(awe_jsobject* jsobject);

/**
 * Returns whether or not a JSValue Object has a certained named property.
 */
bool awe_jsobject_has_property(const(awe_jsobject)* jsobject,
                                          const(awe_string)* property_name);

/**
 * Gets the value of a certain named property of a JSValue Object. You do not
 * need to destroy the returned jsvalue instance, it is owned by the object.
 */
const(awe_jsvalue)* awe_jsobject_get_property(const(awe_jsobject)* jsobject,
                                                        const(awe_string)* property_name);

/**
 * Sets the value of a certained named property of a JSValue Object.
 */
void awe_jsobject_set_property(awe_jsobject* jsobject,
                                          const(awe_string)* property_name,
                                          const(awe_jsvalue)* value);

/**
 * Get the number of key/value pairs in a JSValue object.
 */
size_t awe_jsobject_get_size(awe_jsobject* jsobject);

/**
 * Get a list of all key names as a JSValue Array, you need to call
 * awe_jsarray_destroy on the returned value after you're done using it.
 */
awe_jsarray* awe_jsobject_get_keys(awe_jsobject* jsobject);

/***************************
 * Render Buffer Functions *
 ***************************/

/**
 * Get the width (in pixels) of a RenderBuffer.
 */
int awe_renderbuffer_get_width(const(awe_renderbuffer)* renderbuffer);

/**
 * Get the height (in pixels) of a RenderBuffer.
 */
int awe_renderbuffer_get_height(const(awe_renderbuffer)* renderbuffer);

/**
 * Get the rowspan (number of bytes per row) of a RenderBuffer.
 */
int awe_renderbuffer_get_rowspan(const(awe_renderbuffer)* renderbuffer);

/**
 * Get a pointer to the actual pixel buffer within a RenderBuffer.
 */
const(ubyte)* awe_renderbuffer_get_buffer(const(awe_renderbuffer)* renderbuffer);

/**
 * Copy a RenderBuffer to a specific destination with the same dimensions.
 */
void awe_renderbuffer_copy_to(const(awe_renderbuffer)* renderbuffer,
                                         ubyte* dest_buffer,
                                         int dest_rowspan,
                                         int dest_depth,
                                         bool convert_to_rgba,
                                         bool flip_y);

/**
 * Copy a RenderBuffer to a pixel buffer with a floating-point pixel format
 * for use with game engines like Unity3D.
 */
void awe_renderbuffer_copy_to_float(const(awe_renderbuffer)* renderbuffer,
                                               float* dest_buffer);

/**
 * Save a copy of this RenderBuffer to a PNG image file.
 */
bool awe_renderbuffer_save_to_png(const(awe_renderbuffer)* renderbuffer,
                                             const(awe_string)* file_path,
                                             bool preserve_transparency);

/**
 * Save a copy of this RenderBuffer to a JPEG image file with quality 1 to 100.
 */
bool awe_renderbuffer_save_to_jpeg(const(awe_renderbuffer)* renderbuffer,
                                              const(awe_string)* file_path,
                                              int quality);

/**
 * Get the alpha value at a certain point (origin is top-left). This is
 * useful for alpha-picking.
 *
 * @param   x   The x-value of the point.
 * @param   y   The y-value of the point.
 *
 * @return  Returns the alpha value at a certain point (255 is comppletely
 *          opaque, 0 is completely transparent).
 */
ubyte awe_renderbuffer_get_alpha_at_point(const(awe_renderbuffer)* renderbuffer,
                                                             int x,
                                                             int y);

/**
 * Sets the alpha channel to completely opaque values.
 */
void awe_renderbuffer_flush_alpha(const(awe_renderbuffer)* renderbuffer);

/************************
 * Resource Interceptor *
 ************************/

/**
 * Assign a callback function to intercept requests for resources. You can use
 * this to modify requests before they are sent, respond to requests using
 * your own custom resource-loading back-end, or to monitor requests for
 * tracking purposes.
 *
 * @param   webview     The WebView instance.
 *
 * @param   callback    A function pointer to the callback.
 */
void awe_webview_set_callback_resource_request(
                            awe_webview* webview,
                            awe_resource_response* function(
                                awe_webview* caller,
                                awe_resource_request* request) callback);

/**
 * Assign a callback function to intercept responses to requests. You can use
 * this for tracking/statistic purposes.
 */
void awe_webview_set_callback_resource_response(
                            awe_webview* webview,
                            void function(
                                awe_webview* caller,
                                const(awe_string)* url,
                                int status_code,
                                bool was_cached,
                                int64 request_time_ms,
                                int64 response_time_ms,
                                int64 expected_content_size,
                                const(awe_string)* mime_type) callback);

/**
 * Create a ResourceResponse from a raw block of data. (Buffer is copied)
 */
awe_resource_response* awe_resource_response_create(
                                                  size_t num_bytes,
                                                  ubyte* buffer,
                                                  const(awe_string)* mime_type);

/**
 * Create a ResourceResponse from a file on disk.
 */
awe_resource_response* awe_resource_response_create_from_file(
                                                  const(awe_string)* file_path);

/************************
 * Resource Request     *
 ************************/

/// Cancel the request (this is useful for blocking a resource load).
void awe_resource_request_cancel(awe_resource_request* request);

/// Get the URL associated with this request. (You must destroy returned string)
awe_string* awe_resource_request_get_url(awe_resource_request* request);

/// Get the HTTP method (usually "GET" or "POST") (You must destroy returned string)
awe_string* awe_resource_request_get_method(awe_resource_request* request);

/// Set the HTTP method
void awe_resource_request_set_method(awe_resource_request* request,
                                                const(awe_string)* method);

/// Get the referrer  (You must destroy returned string)
awe_string* awe_resource_request_get_referrer(awe_resource_request* request);

/// Set the referrer
void awe_resource_request_set_referrer(awe_resource_request* request,
                                                  const(awe_string)* referrer);

/// Get extra headers for the request (You must destroy returned string)
awe_string* awe_resource_request_get_extra_headers(awe_resource_request* request);

/**
 * Override extra headers for the request, delimited by /r/n (CRLF).
 *
 * Format should be:
 *   Name: Value/r/nName: Value/r/nName: Value
 *
 * Headers should NOT end in /r/n (CRLF)
 */
void awe_resource_request_set_extra_headers(awe_resource_request* request,
                                                const(awe_string)* headers);

/**
 * Append an extra header to the request.
 *
 * @param   name    Name of the header
 * @param   value   Value of the header
 */
void awe_resource_request_append_extra_header(awe_resource_request* request,
                                                         const(awe_string)* name,
                                                         const(awe_string)* value);

/// Get the number of upload elements (essentially, batches of POST data).
size_t awe_resource_request_get_num_upload_elements(awe_resource_request* request);

/// Get a certain upload element (returned instance is owned by this class)
const(awe_upload_element)* awe_resource_request_get_upload_element(awe_resource_request* request,
                                                                             size_t idx);

/// Clear all upload elements
void awe_resource_request_clear_upload_elements(awe_resource_request* request);

/// Append a file for POST data (adds a new UploadElement)
void awe_resource_request_append_upload_file_path(awe_resource_request* request,
                                                             const(awe_string)* file_path);

/// Append a string of bytes for POST data (adds a new UploadElement)
void awe_resource_request_append_upload_bytes(awe_resource_request* request,
                                                         const(awe_string)* bytes);

/************************
 * Upload Element       *
 ************************/

/// Whether or not this UploadElement is a file
bool awe_upload_element_is_file_path(const(awe_upload_element)* ele);

/// Whether or not this UploadElement is a string of bytes
bool awe_upload_element_is_bytes(const(awe_upload_element)* ele);

/// Get the string of bytes associated with this UploadElement (You must destroy returned string)
awe_string* awe_upload_element_get_bytes(const(awe_upload_element)* ele);

/// Get the file path associated with this UploadElement (You must destroy returned string)
awe_string* awe_upload_element_get_file_path(const(awe_upload_element)* ele);


/************************
 * History Query Result *
 ************************/

/// Destroy the instance (you must call this once you're done using the instance)
void awe_history_query_result_destroy(awe_history_query_result* res);

/// Get the total number of entries
size_t awe_history_query_result_get_size(awe_history_query_result* res);

/// Get a certain entry (you must destroy any returned entry using awe_history_entry_destroy).
/// May return NULL if the index is out of bounds.
awe_history_entry* awe_history_query_result_get_entry_at_index(awe_history_query_result* res,
                                                                          size_t idx);

/************************
 * History Entry        *
 ************************/

/// Destroy the instance
void awe_history_entry_destroy(awe_history_entry* entry);

/// Get the URL of the page
awe_string* awe_history_entry_get_url(awe_history_entry* entry);

/// Get the title of the page
awe_string* awe_history_entry_get_title(awe_history_entry* entry);

/// Get the last time this page was visited (in seconds since epoch)
double awe_history_entry_get_visit_time(awe_history_entry* entry);

/// Get the number of times this page was visited.
int awe_history_entry_get_visit_count(awe_history_entry* entry);

}

/**
 * @mainpage Awesomium C API
 *
 * @section intro_sec Introduction
 *
 * Hi there, welcome to the Awesomium C API docs! Awesomium is a software
 * library that makes it easy to put the web in your applications. Whether
 * that means embedded web browsing, rendering pages as images, streaming
 * pages over the net, or manipulating web content live for some other
 * purpose, Awesomium does it all.
 *
 * Our C API provides much more compatibility than our C++ API at the cost
 * of some extra convenience.
 *
 * To start off, we'd recommend looking at some of the following functions:
 * <pre>
 *    awe_webcore_initialize()
 *    awe_webcore_initialize_default()
 *    awe_webcore_shutdown()
 *    awe_webcore_create_webview()
 *    awe_webview_load_url()
 *    awe_webview_render()
 *    awe_webview_destroy()
 * </pre>
 *
 * To avoid memory leaks, there is one major rule that you must follow in
 * our C API regarding ownership of returned objects: if a function returns
 * a regular pointer to an instance, you must destroy the instance using the
 * relevant method. Otherwise, if a function returns a const pointer to an
 * instance, you should not destroy it (ownership is retained by Awesomium).
 *
 * For example, you must destroy all strings you create in Awesomium:
 *
 * <pre>
 *     awe_string* str = awe_string_create_from_ascii("Hello", strlen("Hello"));
 *
 *     // Use the string somewhere... then destroy it when we are done:
 *
 *     awe_string_destroy(str);
 * </pre>
 *
 * But you should not destroy certain strings returned from certain methods:
 *
 * <pre>
 *     const(awe_string)* str = awe_webcore_get_base_directory();
 *
 *     // We do not need to destroy this string: when a function returns
 *     // a const pointer in Awesomium, it means ownership is retained by
 *     // Awesomium and the instance will be destroyed automatically later.
 * </pre>
 *
 * For more help and tips with the API, please visit our Knowledge Base
 *     <http://support.awesomium.com/faqs>
 *
 * @section usefullinks_sec Useful Links
 * - Awesomium Main: <http://www.awesomium.com>
 * - Support Home: <http://support.awesomium.com>
 *
 * @section copyright_sec Copyright
 * This documentation is copyright (C) 2011 Khrona. All rights reserved.
 * Awesomium is a trademark of Khrona.
 */
