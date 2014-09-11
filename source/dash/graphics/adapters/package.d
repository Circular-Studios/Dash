module dash.graphics.adapters;
public:
import dash.graphics.adapters.adapter;
import dash.graphics.adapters.gl;
version( Windows )
    import dash.graphics.adapters.win32gl;
else version( linux )
    import dash.graphics.adapters.linux;
