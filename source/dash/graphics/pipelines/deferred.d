module dash.graphics.pipelines.deferred;
import dash.graphics.pipelines.pipeline;
import dash.core.gameobject;

class Deferred : Pipeline
{
private:
    // Fake pass 1
    void pass1( GameObject obj )
    {

    }
    
protected:
    
    
public:
    // TODO
    override void initialize() {};
    // TODO
    override void shutdown() {};
    // TODO
    override void refresh() {};

    // TODO: do fo realz
    override void render(GameObject gameObject)
    {
        appendToPass( 0, &pass1, gameObject );
    }
    
    
}