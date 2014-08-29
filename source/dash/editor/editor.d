module dash.editor.editor;
import dash.core.properties;

final abstract class Editor
{
static:
private:
    bool _inEditorMode;

public:
    bool inEditorMode() @property @safe nothrow
    {
        debug return _inEditorMode;
        else return false;
    }

    void inEditorMode( bool iem ) @property @safe nothrow
    {
        debug _inEditorMode = iem;
    }

    void initialize()
    {
        
    }

    void update()
    {

    }
}
