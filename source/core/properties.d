/**
 * Defines template mixins for defining properties in classes.
 * 
 * Authors: Colden Cullen, ColdenCullen@gmail.com
 */
module core.properties;

public import std.traits;

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
	enum Getter = "final " ~ access ~ " @property auto " ~ name ~ "() @safe pure nothrow { return " ~ field.stringof ~ ";}\n";
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
	enum Setter = "final " ~ access ~ " @property void " ~ name ~ "(" ~ typeof(field).stringof ~ " newVal) @safe pure nothrow { " ~ field.stringof ~ " = newVal;}\n";
}
