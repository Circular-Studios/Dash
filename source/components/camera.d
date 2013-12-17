module components.camera;
import core.global, core.gameobject;
import components.icomponent;
import graphics.shaders.ishader;
import math.matrix, math.vector;

import std.signals, std.conv;

class Camera : IComponent
{
public:
	this( GameObject owner )
	{
		super( owner );

		owner.transform.connect( &this.updateViewMatrix );
	}

	@property Matrix!4 viewMatrix() { return _viewMatrix; }

	mixin Signal!( string, string );

private:
	Matrix!4 _viewMatrix;

	void updateViewMatrix( string name, string newVal )
	{
		/*
		auto up = owner.transform.rotation.matrix * Vector!3.up;
		auto lookAt = ( owner.transform.rotation.matrix * Vector!3.forward ) + owner.position;

		auto zAxis = ( lookAt - owner.position ).normalize();
		auto xAxis = up.cross( zAxis ).normalize();
		auto yAxis = zAxis.cross( xAxis );

		result
		*/
	}
}
