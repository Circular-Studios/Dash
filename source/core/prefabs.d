module core.prefabs;
import core.gameobject;
import components;
import math.transform, math.vector, math.quaternion;
import utility.filepath, utility.config;

import yaml;
import std.variant;

final abstract class Prefabs
{
public static:
	alias prefabs this;

	Prefab[string] prefabs;

	void initialize()
	{
		void addObject( Node object )
		{
			auto name = object[ "Name" ].as!string;

			prefabs[ name ] = new Prefab( object );
		}

		foreach( file; FilePath.scanDirectory( FilePath.Resources.Prefabs, "*.yml" ) )
		{
			auto object = Config.loadYaml( file.fullPath );

			if( object.isSequence() )
				foreach( Node innerObj; object )
					addObject( innerObj );
			else
				addObject( object );
		}
	}
}

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

		if( Config.tryGet!string( "Material", prop, yml ) )
			componentReferences ~= Assets.get!Material( prop.get!string );

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

	final GameObject createInstance()
	{
		GameObject result;

		if( scriptClass )
			result = cast(GameObject)scriptClass.create();
		else
			result = new GameObject;

		result.transform.scale.values[ 0..3 ] = transform.scale.values[ 0..3 ];
		result.transform.position.values[ 0..3 ] = transform.position.values[ 0..3 ];
		result.transform.rotation.x = transform.rotation.x;
		result.transform.rotation.y = transform.rotation.y;
		result.transform.rotation.z = transform.rotation.z;
		result.transform.rotation.w = transform.rotation.w;

		foreach( cpn; componentReferences )
			result.addComponent( cpn );

		foreach( cpncls; componentCreations )
			result.addComponent( cast(Component)cpncls.create() );

		result.transform.updateMatrix();

		return result;
	}

private:
	const ClassInfo scriptClass;
	Transform transform;
	Component[] componentReferences;
	ClassInfo[] componentCreations;
}
