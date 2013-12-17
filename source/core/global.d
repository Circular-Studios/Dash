module core.global;

template Property( string Type, string name, string setterAccess = "private", string checkExpr = "true" ) {
	const char[] Property = 
		"private " ~ Type ~ " _" ~ name ~ ";\n" ~
		"public @property " ~ Type ~ " " ~ name ~ "() { return _" ~ name ~ "; }\n" ~
		setterAccess ~ " @property void " ~ name ~ "( " ~ Type ~ " val )" ~
		"{ if( " ~ checkExpr ~ " && val != _" ~ name ~ " ) _" ~ name ~ " = val; }\n";
}

template BackedProperty( string Type, string field, string name, string setterAccess = "private", string checkExpr = "true" ) {
	const char[] BackedProperty = 
		"public @property " ~ Type ~ " " ~ name ~ "() { return " ~ field ~ "; }\n" ~
		setterAccess ~ " @property void " ~ name ~ "( " ~ Type ~ " val )" ~
		"{ if( " ~ checkExpr ~ " && val != _" ~ name ~ " ) " ~ field ~ " = val; }\n";
}

template EmmittingProperty( string Type, string name, string setterAccess = "private", string checkExpr = "true" ) {
	const char[] EmmittingProperty = 
		"private " ~ Type ~ " _" ~ name ~ ";\n" ~
		"public @property " ~ Type ~ " " ~ name ~ "() { return _" ~ name ~ "; }\n" ~
		setterAccess ~ " @property void " ~ name ~ "( " ~ Type ~ " val )" ~
		"{ if( " ~ checkExpr ~ " && val != _" ~ name ~ " ) { _" ~ name ~ " = val; emit( \"" ~ name ~ "\", to!string( val ) ); } }\n";
}

template EmmittingBackedProperty( string Type, string field, string name, string setterAccess = "private", string checkExpr = "true" ) {
	const char[] EmmittingBackedProperty = 
		"public @property " ~ Type ~ " " ~ name ~ "() { return " ~ field ~ "; }\n" ~
		setterAccess ~ " @property void " ~ name ~ "( " ~ Type ~ " val )" ~
		"{ if( " ~ checkExpr ~ " && val != " ~ field ~ " ) { " ~ field ~ " = val; emit( \"" ~ name ~ "\", to!string( val ) ); } }\n";
}

void destroy_s( T )( T t )
{
	if( t )
	{
		destroy( t );
	}
}
