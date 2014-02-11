module components.material;
import core.properties;
import components;

class Material : Component
{
public:
	mixin Property!( "Texture", "diffuse" );
	mixin Property!( "Texture", "normal" );

	this()
	{
		super( null );
	}

private:
	
}
