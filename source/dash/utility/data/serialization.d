module dash.utility.data.serialization;

// Serialization attributes
public import vibe.data.serialization: asArray, byName, ignore, name, optional;
/// Rename a field in the ddl.
alias rename = name;
