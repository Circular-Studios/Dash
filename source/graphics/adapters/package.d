module graphics.adapters;
public:
import graphics.adapters.adapter;
version( Windows )
    import graphics.adapters.win32;
else version( OSX )
    import graphics.adapters.mac;
else version( linux )
    import graphics.adapters.linux;
