module dash.graphics.pipelines.deferred;
import dash.graphics.pipelines.pipeline;
import dash.core.gameobject;

class Deferred : Pipeline
{
private:

    // Fake prepass 1
    void prePass1()
    {
        
    }

    // Fake pass 1
    void pass1( GameObject obj )
    {
        
    }

    // Fake postpass1
    void postPass1()
    {

    }

    // Fake pass2
    void pass2( GameObject obj )
    {
        
    }
    
protected:
    
    
public:
    override void initialize() 
    {
        // Pipeline initialize code here...



        // Add this pipeline to all render passes
        addToPass( 0, this, &prePass1, &pass1, &postPass1 );
        addToPass( 1, this, null, &pass1, null );
    }
    override void shutdown() 
    {
        // Pipeline shutdown code here...



        // Remove this pipeline from all render passes
        removeFromPass( 0, this );
        removeFromPass( 1, this );
    }
    override void refresh()
    {
        // Pipeline refresh code here...



    }
    override void render(GameObject gameObject)
    {
        // Append the object to render lists for all
        appendToPass( 0, this, gameObject );
        appendToPass( 0, this, gameObject );
    }
    
    
}