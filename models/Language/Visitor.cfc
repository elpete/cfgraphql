component accessors="true" {

    variables.QueryDocumentKeys = {
        "Name" = [],

        "Document" = [ "definitions" ],
        "OperationDefinition" = [
        "name",
        "variableDefinitions",
        "directives",
        "selectionSet"
        ],
        "VariableDefinition" = [ "variable", "type", "defaultValue" ],
        "Variable" = [ "name" ],
        "SelectionSet" = [ "selections" ],
        "Field" = [ "alias", "name", "args", "directives", "selectionSet" ],
        "Argument" = [ "name", "value" ],

        "FragmentSpread" = [ "name", "directives" ],
        "InlineFragment" = [ "typeCondition", "directives", "selectionSet" ],
        "FragmentDefinition" = [
        "name",
        // Note: fragment variable definitions are experimental and may be changed
        // or removed in the future.
        "variableDefinitions",
        "typeCondition",
        "directives",
        "selectionSet"
        ],

        "IntValue" = [],
        "FloatValue" = [],
        "StringValue" = [],
        "BooleanValue" = [],
        "NullValue" = [],
        "EnumValue" = [],
        "ListValue" = [ "values" ],
        "ObjectValue" = [ "fields" ],
        "ObjectField" = [ "name", "value" ],

        "Directive" = [ "name", "args" ],

        "NamedType" = [ "name" ],
        "ListType" = [ "type" ],
        "NonNullType" = [ "type" ],

        "SchemaDefinition" = [ "directives", "operationTypes" ],
        "OperationTypeDefinition" = [ "type" ],

        "ScalarTypeDefinition" = [ "description", "name", "directives" ],
        "ObjectTypeDefinition" = [
        "description",
        "name",
        "interfaces",
        "directives",
        "fields"
        ],
        "FieldDefinition" = [ "description", "name", "args", "type", "directives" ],
        "InputValueDefinition" = [
        "description",
        "name",
        "type",
        "defaultValue",
        "directives"
        ],
        "InterfaceTypeDefinition" = [ "description", "name", "directives", "fields" ],
        "UnionTypeDefinition" = [ "description", "name", "directives", "types" ],
        "EnumTypeDefinition" = [ "description", "name", "directives", "values" ],
        "EnumValueDefinition" = [ "description", "name", "directives" ],
        "InputObjectTypeDefinition" = [ "description", "name", "directives", "fields" ],

        "DirectiveDefinition" = [ "description", "name", "args", "locations" ],

        "SchemaExtension" = [ "directives", "operationTypes" ],

        "ScalarTypeExtension" = [ "name", "directives" ],
        "ObjectTypeExtension" = [ "name", "interfaces", "directives", "fields" ],
        "InterfaceTypeExtension" = [ "name", "directives", "fields" ],
        "UnionTypeExtension" = [ "name", "directives", "types" ],
        "EnumTypeExtension" = [ "name", "directives", "values" ],
        "InputObjectTypeExtension" = [ "name", "directives", "fields" ]
    };

    variables.BREAK = {};

    function visit( root, visitor, visitorKeys = QueryDocumentKeys ) {
        var stack = "";
        var inArray = isArray( root );
        var keys = [ root ];
        var index = 0;
        var edits = [];
        var node = "";
        var key = "";
        var parent = javacast( "null", "" );
        var path = [];
        var ancestors = [];
        var newRoot = root;

        writeDump( var = local, expand = false );

        do {
            index++;
            var isLeaving = index == arrayLen( keys ) + 1;
            var isEdited = isLeaving && arrayLen( edits ) != 0;
            if ( isLeaving ) {
                key = arrayIsEmpty( ancestors ) ? javacast( "null", "" ) : path[ arrayLen( path ) ];
                node = parent;
                parent = pop( ancestors );
                if ( isEdited ) {
                    node = duplicate( node );
                    var editOffset = 1;
                    for ( var i = 1; i < arrayLen( edits ); i++ ) {
                        var editKey = edits[ i ][ 1 ];
                        var editValue = edits[ i ][ 2 ];
                        if ( inArray ) {
                            editKey -= editOffset;
                        }

                        if ( inArray && isNull( editValue ) ) {
                            arrayDeleteAt( node, editKey );
                            editOffset++;
                        }
                        else {
                            node[ editKey ] = editValue;
                        }
                    }
                }
                index = stack.index;
                keys = stack.keys;
                edits = stack.edits;
                inArray = stack.inArray;
                stack = isSimpleValue( stack.prev ) ? javacast( "null", "" ) : stack.prev;
            }
            else {
                key = isNull( parent ) ? javacast( "null", "" ) : ( inArray ? index : keys[ index ] );
                node = isNull( parent ) ? newRoot : parent[ key ];
                if ( isNull( node ) || ( isSimpleValue( node ) && node == "" ) ) {
                    continue;
                }
                if ( ! isNull( parent ) ) {
                    path.append( key );
                }
            }

            var result = "";
            if ( ! isArray( node ) ) {
                if ( ! isNode( node ) ) {
                    throw(
                    type = "CFGraphQLVisitorError",
                    message = "Invalid AST Node: #serializeJSON( node )#"
                    );
                }
                var visitFn = getVisitFn( visitor, node.kind, isLeaving );
                if ( ! isNull( visitFn ) ) {
                    result = visitFn(
                        node,
                        isNull( key ) ? javacast( "null", "" ) : key,
                        isNull( parent ) ? javacast( "null", "" ) : parent,
                        isNull( path ) ? "" : path,
                        ancestors
                    );

                    if ( ! isNull( result ) && result == variables.BREAK ) {
                        break;
                    }

                    if ( ! isNull( result ) && result == false ) {
                        if ( ! isLeaving ) {
                            pop( path );
                            continue;
                        }
                    }
                    else if ( ! isNull( result ) ) {
                        edits.append( [ key, result ] );
                        if ( ! isLeaving ) {
                            if ( isNode( result ) ) {
                                node = result;
                            }
                            else {
                                pop( path );
                                continue;
                            }
                        }
                    }
                }
            }

            if ( isNull( result ) && isEdited ) {
                edits.append( [ key, node ] );
            }

            if ( isLeaving ) {
                pop( path );
            }
            else {
                stack = {
                    inArray = inArray,
                    index = index,
                    keys = keys,
                    edits = edits,
                    prev = stack
                };
                inArray = isArray( node );
                keys = inArray ? node : ( isNull( visitorKeys[ node.kind ] ) ? [] : visitorKeys[ node.kind ] );
                index = 0;
                edits = [];
                if ( ! isNull( parent ) ) {
                    ancestors.append( parent );
                }
                parent = node;
            }
        } while( ! isNull( stack ) );

        if ( arrayLen( edits ) != 0 ) {
            newRoot = edits[ arrayLen( edits ) ][ 2 ];
        }

        return newRoot;
    }

    private function isNode( maybeNode ) {
        return ! isNull( maybeNode ) &&
        isStruct( maybeNode ) &&
        maybeNode.keyExists( "kind" ) &&
        isValid( "string", maybeNode.kind );
    }

    private any function pop( required array arr ) {
        if ( arrayIsEmpty( arr ) ) {
            return javacast( "null", "" );
        }
        var length = arrayLen( arr );
        var value = arr[ length ];
        arrayDeleteAt( arr, length );
        return value;
    }

    private any function getVisitFn( visitor, kind, isLeaving ) {
        if ( structKeyExists( visitor, kind ) ) {
            var kindVisitor = visitor[ kind ];
            if ( ! isLeaving && isCustomFunction( kindVisitor ) ) {
                return kindVisitor;
            }
            if ( isLeaving ) {
                if ( structKeyExists( kindVisitor, "leave" ) ) {
                    var kindSpecificVisitor = kindVisitor.leave;
                    if ( isCustomFunction( kindSpecificVisitor ) ) {
                        return kindSpecificVisitor;
                    }
                }
            }
            else {
                if ( structKeyExists( kindVisitor, "enter" ) ) {
                    var kindSpecificVisitor = kindVisitor.enter;
                    if ( isCustomFunction( kindSpecificVisitor ) ) {
                        return kindSpecificVisitor;
                    }
                }
            }
        }
        else {
            if ( isLeaving ) {
                if ( structKeyExists( visitor, "leave" ) ) {
                    var specificVisitor = visitor.leave;
                    if ( isCustomFunction( specificVisitor ) ) {
                        return specificVisitor;
                    }
                    if ( structKeyExists( specificVisitor, kind ) ) {
                        var specificKindVisitor = specificVisitor[ kind ];
                        if ( isCustomFunction( specificKindVisitor ) ) {
                            return specificKindVisitor;
                        }
                    }
                }
            }
            else {
                if ( structKeyExists( visitor, "enter" ) ) {
                    var specificVisitor = visitor.enter;
                    if ( isCustomFunction( specificVisitor ) ) {
                        return specificVisitor;
                    }
                    if ( structKeyExists( specificVisitor, kind ) ) {
                        var specificKindVisitor = specificVisitor[ kind ];
                        if ( isCustomFunction( specificKindVisitor ) ) {
                            return specificKindVisitor;
                        }
                    }
                }
            }
        }
    }


}
