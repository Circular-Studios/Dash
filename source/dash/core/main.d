module dash.core.main;
import dash.core.dgame, dash.editor.editor;

/**
 * Initializes reflection things.
 */
static this()
{
    ClassInfo gameType = typeid(DGame);
    ClassInfo editorType = typeid(Editor);

    foreach( mod; ModuleInfo )
    {
        foreach( klass; mod.localClasses )
        {
            // Find the appropriate game loop.
            if( klass.base == typeid(DGame) )
                gameType = klass;
            else if( klass.base == typeid(Editor) )
                editorType = klass;
        }
    }

    DGame.instance = cast(DGame)gameType.create();
    DGame.instance.editor = cast(Editor)editorType.create();
}

version( unittest ) { }
else
{
    import dash.core.dgame;
    import std.stdio;

    /// Does exactly what you think it does.
    void main()
    {
        if( !DGame.instance )
        {
            writeln( "No game supplied." );
            return;
        }

        DGame.instance.run();
    }
}
