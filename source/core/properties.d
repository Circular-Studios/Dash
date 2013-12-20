module core.properties;

public:
template Property( string type, string name, string setterAccess = "private", string checkExpr = "true" )
{
	immutable char[] Property =
		Field!( type, name ) ~
		Getter!( type, name ) ~
		Setter!( setterAccess, type, name, checkExpr ) ~
		"\n";
}

template BackedProperty( string type, string field, string name, string setterAccess = "private", string checkExpr = "true" )
{
	immutable char[] BackedProperty = 
		Getter!( type, name, field ) ~
		Setter!( setterAccess, type, name, checkExpr, field ) ~
		"\n";
}

template EmmittingProperty( string type, string name, string setterAccess = "private", string checkExpr = "true" )
{
	immutable char[] EmmittingProperty = 
		Field!( type, name ) ~
		Getter!( type, name ) ~
		EmmittingSetter!( setterAccess, type, name, checkExpr ) ~
		"\n";
}

template EmmittingBackedProperty( string type, string field, string name, string setterAccess = "private", string checkExpr = "true" )
{
	immutable char[] EmmittingBackedProperty = 
		Getter!( type, name, field ) ~
		EmmittingSetter!( setterAccess, type, name, checkExpr, field ) ~
		"\n";
}

template DirtyProperty( string type, string name, string updateFunc, string setterAccess = "private", string checkExpr = "true" )
{
	immutable char[] DirtyProperty =
		Field!( type, name ) ~
		IsDirtyField!name ~
		DirtyGetter!( type, name, updateFunc ) ~
		Setter!( setterAccess, type, name, checkExpr ) ~
		"\n";
}

template BackedDirtyProperty( string type, string field, string name, string updateFunc, string setterAccess = "private", string checkExpr = "true" )
{
	immutable char[] BackedDirtyProperty =
		IsDirtyField!name ~
		DirtyGetter!( type, name, updateFunc, field ) ~
		Setter!( setterAccess, type, name, checkExpr, field ) ~
		"\n";
}

template EmmittingDirtyProperty( string type, string name, string updateFunc, string setterAccess = "private", string checkExpr = "true" )
{
	immutable char[] EmmittingDirtyProperty =
		Field!( type, name ) ~
		IsDirtyField!name ~
		DirtyGetter!( type, name, updateFunc ) ~
		EmmittingSetter!( setterAccess, type, name, checkExpr ) ~
		"\n";
}

template BackedEmmittingDirtyProperty( string type, string field, string name, string updateFunc, string setterAccess = "private", string checkExpr = "true" )
{
	immutable char[] EmmittingDirtyProperty =
		IsDirtyField!name ~
		DirtyGetter!( type, name, updateFunc, field ) ~
		EmmittingSetter!( setterAccess, type, name, checkExpr, field ) ~
		"\n";
}

template PropertySetDirty( string type, string name, string dirtyProp, string setterAccess = "private", string checkExpr = "true" )
{
	immutable char[] PropertySetDirty =
		Field!( type, name ) ~
		Getter!( type, name ) ~
		DirtySetter!( setterAccess, type, name, dirtyField, setCond ) ~
		"\n";
}

template EmmittingPropertySetDirty( string type, string name, string dirtyProp, string setterAccess = "private", string checkExpr = "true" )
{
	immutable char[] EmmittingPropertySetDirty =
		Field!( type, name ) ~
		Getter!( type, name ) ~
		EmmittingDirtySetter!( setterAccess, type, name, dirtyProp, checkExpr ) ~
		"\n";
}

template BackedPropertySetDirty( string type, string field, string name, string dirtyProp, string setterAccess = "private", string checkExpr = "true" )
{
	immutable char[] PropertySetDirty =
		Getter!( type, name, field ) ~
		DirtySetter!( setterAccess, type, name, dirtyField, checkExpr, field ) ~
		"\n";
}

template BackedEmmittingPropertySetDirty( string type, string field, string name, string dirtyProp, string setterAccess = "private", string checkExpr = "true" )
{
	immutable char[] EmmittingPropertySetDirty =
		Getter!( type, name, field ) ~
		EmmittingDirtySetter!( setterAccess, type, name, dirtyField, checkExpr, field ) ~
		"\n";
}

private:
template FieldName( string name, string field = "" )
{
	immutable char[] FieldName = field.length ? field : "_" ~ name;
}
template Field( string type, string name )
{
	immutable char[] Field = "private " ~ type ~ " " ~ FieldName!name ~ ";";
}

template DirtyFieldName( string name )
{
	immutable char[] DirtyFieldName = FieldName!name ~ "IsDirty";
}
template IsDirtyField( string name )
{
	immutable char[] IsDirtyField = "private bool " ~ DirtyFieldName!name ~ " = false;";
}

template Getter( string type, string name, string fieldName = "" )
{
	immutable char[] Getter =
		"public @property " ~ type ~ " " ~ name ~ "(){" ~
		"return " ~ FieldName!( name, fieldName ) ~ "; }";
}
template DirtyGetter( string type, string name, string dirtyUpdateFunc, string fieldName = "" )
{
	immutable char[] DirtyGetter = 
		"public @property " ~ type ~ " " ~ name ~ "() {" ~
		"if( " ~ DirtyFieldName!name ~ " ) {" ~ dirtyUpdateFunc ~ "();" ~
		DirtyFieldName!name ~ " = false; }" ~
		"return " ~ FieldName!( name, fieldName ) ~ "; }";
}

template SetterHeader( string access, string type, string name )
{
	immutable char[] SetterHeader = access ~ " @property void " ~ name ~ "( " ~ type ~ " _newVal ) {";
}
template SetterAssignment( string name, string fieldName = "" )
{
	immutable char[] SetterAssignment = FieldName!( name, fieldName ) ~ " = _newVal;";
}
template SetterCond( string setCond, string name, string fieldName )
{
	immutable char[] SetterCond = setCond ~ " && _newVal != " ~ FieldName!( name, fieldName );
}
template SetterEmit( string name )
{
	immutable char[] SetterEmit = "emit( \"" ~ name ~ "\", to!string( _newVal ) );";
}
template Setter( string access, string type, string name, string setCond, string fieldName = "" )
{
	immutable char[] Setter =
		SetterHeader!( access, type, name ) ~
		"if( " ~ SetterCond!( setCond, name, fieldName ) ~ " ) { " ~
		SetterAssignment!( name, fieldName ) ~ " } }";
}
template EmmittingSetter( string access, string type, string name, string setCond, string fieldName = "" )
{
	immutable char[] EmmittingSetter =
		SetterHeader!( access, type, name ) ~
		"if( " ~ SetterCond!( setCond, name, fieldName ) ~ " ) { " ~
		SetterAssignment!( name, fieldName ) ~
		SetterEmit!name ~ " } }";
}
template DirtySetter( string access, string type, string name, string dirtyField, string setCond, string fieldName = "" )
{
	immutable char[] DirtySetter =
		SetterHeader!( access, type, name ) ~
		"if( " ~ SetterCond!( setCond, name, fieldName ) ~ " ) { " ~
		SetterAssignment!( name, fieldName ) ~
		DirtyFieldName!dirtyField ~ " = true; } }";
}
template EmmittingDirtySetter( string access, string type, string name, string dirtyField, string setCond, string fieldName = "" )
{
	immutable char[] EmmittingDirtySetter =
		SetterHeader!( access, type, name ) ~
		"if( " ~ SetterCond!( setCond, name, fieldName ) ~ " ) { " ~
		SetterAssignment!( name, fieldName ) ~
		SetterEmit!name ~
		DirtyFieldName!dirtyField ~ " = true; } }";
}
