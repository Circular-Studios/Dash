module dash.core.reflection;
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
