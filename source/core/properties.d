/**
 * Defines template mixins for defining properties in classes.
 * 
 * Authors: Colden Cullen, ColdenCullen@gmail.com
 */
module core.properties;

public import std.traits;
import std.array;

enum AccessModifier : string
{
	Public = "public",
	Protected = "protected",
	Private = "private",
}

/**
 * Generates a getter and setter for a field.
 * 
 * Params:
 * 	field = 				The field to generate the property for.
 * 	setterAccess = 			The access modifier for the setter function.
 * 	getterAccess = 			The access modifier for the getter funciton.
 * 	name = 					The name of the property functions. Defaults to the field name minus the first character. Meant for fields that start with underscores.
 */
template Property( alias field, AccessModifier setterAccess = AccessModifier.Protected, AccessModifier getterAccess = AccessModifier.Public, string name = field.stringof[ 1..$ ] )
{
	enum Property = Getter!( field, getterAccess, name ) ~ Setter!( field, setterAccess, name );
}

/**
 * Generates a getter for a field.
 * 
 * Params:
 * 	field = 				The field to generate the property for.
 * 	access = 				The access modifier for the getter function.
 * 	name = 					The name of the property functions. Defaults to the field name minus the first character. Meant for fields that start with underscores.
 */
template Getter( alias field, AccessModifier access = AccessModifier.Protected, string name = field.stringof[ 1..$ ] )
{
	enum Getter = q{
		final $access @property auto $name() @safe pure nothrow
		{
			return $field;
		}}
		.replace( "$field", field.stringof ).replace( "$access", cast(string)access ).replace( "$name", name );
}

/**
 * Generates a getter for a field that can be marked as dirty. Calls updateFunc if is dirty.
 * 
 * Params:
 * 	field = 				The field to generate the property for.
 * 	updateFunc = 			The function to call when the function is dirty.
 * 	access = 				The access modifier for the getter function.
 * 	name = 					The name of the property functions. Defaults to the field name minus the first character. Meant for fields that start with underscores.
 */
template DirtyGetter( alias field, alias updateFunc, AccessModifier access = AccessModifier.Protected, string name = field.stringof[ 1..$ ] )
	if( is( typeof(T) : IDirtyable ) )
{
	enum DirtyGetter = q{
		final $access @property auto $name() @safe pure nothrow
		{
			if( $field.isDirty() )
				$updateFunc();
			return $field;
		}}
		.replace( "$field", field.stringof ).replace( "$updateFunc", updateFunc.stringof ).replace( "$access", cast(string)access ).replace( "$name", name );
}

/// ditto
template DirtyGetter( alias field, alias updateFunc, AccessModifier access = AccessModifier.Protected, string name = field.stringof[ 1..$ ] )
	if( !is( typeof(T) : IDirtyable ) )
{
	enum DirtyGetter = q{
		$type $dirtyFieldName;
		final $access @property auto $name() @safe pure nothrow
		{
			if( $field != $dirtyFieldName )
				$updateFunc();
			return $field;
		}}
		.replace( "$field", field.stringof ).replace( "$updateFunc", updateFunc.stringof ).replace( "$access", cast(string)access ).replace( "$name", name )
		.replace( "$type", typeof(field).stringof ).replace( "$dirtyFieldName", "_" ~ field.stringof ~ "Prev" );
}

/**
 * Generates a setter for a field.
 * 
 * Params:
 * 	field = 				The field to generate the property for.
 * 	access = 				The access modifier for the setter function.
 * 	name = 					The name of the property functions. Defaults to the field name minus the first character. Meant for fields that start with underscores.
 */
template Setter( alias field, AccessModifier access = AccessModifier.Protected, string name = field.stringof[ 1..$ ] )
{
	enum Setter = q{
		final $access @property void $name( $type newVal ) @safe pure nothrow
		{
			$field = newVal;
		}}
		.replace( "$field", field.stringof ).replace( "$access", cast(string)access ).replace( "$name", name )
		.replace( "$type", typeof(field).stringof );
}

/**
 * Requires implementation of the isDirty property.
 */
interface IDirtyable
{
	@property bool isDirty();
}
