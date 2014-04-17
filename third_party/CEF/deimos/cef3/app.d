module deimos.cef3.app;

// Copyright (c) 2012 Marshall A. Greenblatt. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//    * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//    * Neither the name of Google Inc. nor the name Chromium Embedded
// Framework nor the names of its contributors may be used to endorse
// or promote products derived from this software without specific prior
// written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ---------------------------------------------------------------------------

extern(C) {
    public import deimos.cef3.base;
    public import deimos.cef3.browser_process_handler;
    public import deimos.cef3.render_process_handler;
    public import deimos.cef3.resource_bundle_handler;
    public import deimos.cef3.scheme;
    public import deimos.cef3.command_line;


    ///
    // This function should be called from the application entry point function to
    // execute a secondary process. It can be used to run secondary processes from
    // the browser client executable (default behavior) or from a separate
    // executable specified by the CefSettings.browser_subprocess_path value. If
    // called for the browser process (identified by no "type" command-line value)
    // it will return immediately with a value of -1. If called for a recognized
    // secondary process it will block until the process should exit and then return
    // the process exit code. The |application| parameter may be NULL.
    ///
    int cef_execute_process(const(cef_main_args_t)* args, cef_app_t* application,
                        void* windows_sandbox_info);

    ///
    // This function should be called on the main application thread to initialize
    // the CEF browser process. The |application| parameter may be NULL. A return
    // value of true (1) indicates that it succeeded and false (0) indicates that it
    // failed.
    ///
    int cef_initialize(const(cef_main_args_t)* args, const(cef_settings_t)* settings,
                       cef_app_t* application, void* windows_sandbox_info);

    ///
    // This function should be called on the main application thread to shut down
    // the CEF browser process before the application exits.
    ///
    void cef_shutdown();

    ///
    // Perform a single iteration of CEF message loop processing. This function is
    // used to integrate the CEF message loop into an existing application message
    // loop. Care must be taken to balance performance against excessive CPU usage.
    // This function should only be called on the main application thread and only
    // if cef_initialize() is called with a CefSettings.multi_threaded_message_loop
    // value of false (0). This function will not block.
    ///
    void cef_do_message_loop_work();

    ///
    // Run the CEF message loop. Use this function instead of an application-
    // provided message loop to get the best balance between performance and CPU
    // usage. This function should only be called on the main application thread and
    // only if cef_initialize() is called with a
    // CefSettings.multi_threaded_message_loop value of false (0). This function
    // will block until a quit message is received by the system.
    ///
    void cef_run_message_loop();

    ///
    // Quit the CEF message loop that was started by calling cef_run_message_loop().
    // This function should only be called on the main application thread and only
    // if cef_run_message_loop() was used.
    ///
    void cef_quit_message_loop();

    ///
    // Set to true (1) before calling Windows APIs like TrackPopupMenu that enter a
    // modal message loop. Set to false (0) after exiting the modal message loop.
    ///
    void cef_set_osmodal_loop(int osModalLoop);

    ///
    // Implement this structure to provide handler implementations. Methods will be
    // called by the process and/or thread indicated.
    ///
    struct cef_app_t {
        ///
        // Base structure.
        ///
        cef_base_t base;

        ///
        // Provides an opportunity to view and/or modify command-line arguments before
        // processing by CEF and Chromium. The |process_type| value will be NULL for
        // the browser process. Do not keep a reference to the cef_command_line_t
        // object passed to this function. The CefSettings.command_line_args_disabled
        // value can be used to start with an NULL command-line object. Any values
        // specified in CefSettings that equate to command-line arguments will be set
        // before this function is called. Be cautious when using this function to
        // modify command-line arguments for non-browser processes as this may result
        // in undefined behavior including crashes.
        ///
        extern(System) void function(cef_app_t, const(cef_string_t)*, cef_command_line_t*)
            on_before_command_line_processing;

        ///
        // Provides an opportunity to register custom schemes. Do not keep a reference
        // to the |registrar| object. This function is called on the main thread for
        // each process and the registered schemes should be the same across all
        // processes.
        ///
        extern(System) void function(cef_app_t*, cef_scheme_registrar_t*) on_register_custom_schemes;

        ///
        // Return the handler for resource bundle events. If
        // CefSettings.pack_loading_disabled is true (1) a handler must be returned.
        // If no handler is returned resources will be loaded from pack files. This
        // function is called by the browser and render processes on multiple threads.
        ///
        extern(System) cef_resource_bundle_handler_t* function(cef_app_t*) get_resource_bundle_handler;

        ///
        // Return the handler for functionality specific to the browser process. This
        // function is called on multiple threads in the browser process.
        ///
        extern(System) cef_browser_process_handler_t* function(cef_app_t*) get_browser_process_handler;

        ///
        // Return the handler for functionality specific to the render process. This
        // function is called on the render process main thread.
        ///
        extern(System) cef_render_process_handler_t* function(cef_app_t*) get_render_process_handler;
    }

}