module core.prefab;
import core.gameobject;
import components.component, components.assets, components.mesh, components.texture;
import utility.config;
import math.transform, math.vector, math.quaternion;

import yaml;
import std.variant;

final class Prefab
{
public:
	this( Node yml )
	{
		transform = new Transform;
		Variant prop;
		Node innerNode;

		// Try to get from script
		if( Config.tryGet!string( "Script.ClassName", prop, yml ) )
			scriptClass = ClassInfo.find( prop.get!string );
		else
			scriptClass = null;

		if( Config.tryGet!string( "Camera", prop, yml ) )
		{
			//TODO: Setup camera
		}

		if( Config.tryGet!string( "Texture", prop, yml ) )
			componentReferences ~= Assets.get!Texture( prop.get!string );

		if( Config.tryGet!string( "AwesomiumView", prop, yml ) )
		{
			//TODO: Initialize Awesomium view
		}

		if( Config.tryGet!string( "Mesh", prop, yml ) )
			componentReferences ~= Assets.get!Mesh( prop.get!string );

		if( Config.tryGet( "Transform", innerNode, yml ) )
		{
			Vector!3 transVec;
			if( Config.tryGet( "Scale", transVec, innerNode ) )
				transform.scale = transVec;
			if( Config.tryGet( "Position", transVec, innerNode ) )
				transform.position = transVec;
			if( Config.tryGet( "Rotation", transVec, innerNode ) )
				transform.rotation = Quaternion.fromEulerAngles( transVec );
		}
	}

	this()
	{
		transform = new Transform;
		scriptClass = null;
	}

	GameObject createInstance()
	{
		GameObject result;

		if( scriptClass )
			result = cast(GameObject)scriptClass.create();
		else
			result = new GameObject;

		result.transform.scale = transform.scale;
		result.transform.position = transform.position;
		result.transform.rotation = transform.rotation;

		foreach( cpn; componentReferences )
			result.addComponent( cpn );

		foreach( cpncls; componentCreations )
			result.addComponent( cast(Component)cpncls.create() );

		return result;
	}

private:
	const ClassInfo scriptClass;
	Transform transform;
	Component[] componentReferences;
	ClassInfo[] componentCreations;
}