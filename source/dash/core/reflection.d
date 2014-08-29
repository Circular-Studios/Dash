module dash.core.reflection;
import dash.core.dgame, dash.editor.editor;

/**
 * Initializes reflection things.
 */
static this()
{
    ClassInfo editorType = typeid(Editor);

    foreach( mod; ModuleInfo )
    {
        foreach( klass; mod.localClasses )
        {
            // Find the appropriate game loop.
            if( klass.base == typeid(DGame) )
                DGame.instance = cast(DGame)klass.create();
            else if( klass.base == typeid(Editor) )
                editorType = klass;
        }
    }

    DGame.instance.editor = cast(Editor)editorType.create();
}
