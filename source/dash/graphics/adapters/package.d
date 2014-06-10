module dash.graphics.adapters;
public:
import dash.graphics.adapters.adapter;
version( Windows )
    import dash.graphics.adapters.win32;
else version( OSX )
    import dash.graphics.adapters.mac;
else version( linux )
    import dash.graphics.adapters.linux;
