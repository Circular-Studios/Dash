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
		.replaceMap( [
			"$field": field.stringof, "$name": name,
			"$access": cast(string)access ] );
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
		final $access @property auto $name() $attributes
		{
			if( $field.isDirty() )
				$updateFunc();
			return $field;
		}}
		.replaceMap( [
			"$field": field.stringof, "$updateFunc": updateFunc.stringof,
			"$name": name, "$access": cast(string)access,
			"$attributes": functionTraitsString!updateFunc ] );
}

/// ditto
template DirtyGetter( alias field, alias updateFunc, AccessModifier access = AccessModifier.Protected, string name = field.stringof[ 1..$ ] )
	if( !is( typeof(T) : IDirtyable ) )
{
	enum DirtyGetter = q{
		private $type $dirtyFieldName;
		final $access @property auto $name() $attributes
		{
			if( $field != $dirtyFieldName )
				$updateFunc;
			return $field;
		}}
		.replaceMap( [
			"$field": field.stringof, "$updateFunc": updateFunc.stringof,
			"$name": name, "$access": cast(string)access,
		 	"$type": typeof(field).stringof,
		 	"$dirtyFieldName": "_" ~ field.stringof ~ "Prev",
		 	"$attributes": functionTraitsString!updateFunc ] );
}

/**
 * Like DirtyGetter, but instead of tracking if the field is dirty, it tracks if the this scope is dirty
 * 
 * Params:
 * 	field = 				The field to generate the property for.
 * 	updateFunc = 			The function to call when the function is dirty.
 * 	access = 				The access modifier for the getter function.
 * 	name = 					The name of the property functions. Defaults to the field name minus the first character. Meant for fields that start with underscores.
 */
template ThisDirtyGetter( alias field, alias updateFunc, AccessModifier access = AccessModifier.Protected, string name = field.stringof[ 1..$ ] )
{
	enum ThisDirtyGetter = q{
		final $access @property auto $name() $attributes
		{
			if( isDirty() )
				$updateFunc;
			return $field;
		}}
		.replaceMap( [
			"$field": field.stringof, "$updateFunc": updateFunc.stringof,
			"$name": name,"$access": cast(string)access,
			"$attributes": functionTraitsString!updateFunc ] );
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
		.replaceMap( [
			"$field": field.stringof, "$access": cast(string)access,
			"$name": name, "$type": typeof(field).stringof ] );
}

/**
 * Requires implementation of the isDirty property.
 */
shared interface IDirtyable
{
	@property bool isDirty();
}

private:
T replaceMap( T, TKey, TValue )( T base, TKey[TValue] replaceMap ) if( isSomeString!T && isSomeString!TKey && isSomeString!TValue )
{
	auto result = base;

	foreach( key, value; replaceMap )
	{
		result = result.replace( key, value );
	}

	return result;
}

string functionTraitsString( alias func )()
{
	string result = "";
	enum funcAttr = functionAttributes!func;
	
	if( funcAttr & FunctionAttribute.trusted )
		result ~= " @trusted";
	if( funcAttr & FunctionAttribute.safe )
		result ~= " @safe";
	if( funcAttr & FunctionAttribute.pure_ )
		result ~= " pure";
	if( funcAttr & FunctionAttribute.nothrow_ )
		result ~= " nothrow";
	if( funcAttr & FunctionAttribute.ref_ )
		result ~= " ref";
	
	return result;
}
