component accessors="true" {

    variables.TokenKind = {
        "SOF" = "<SOF>",
        "EOF" = "<EOF>",
        "BANG" = "!",
        "DOLLAR" = "$",
        "AMP" = "&",
        "PAREN_L" = "(",
        "PAREN_R" = ")",
        "SPREAD" = "...",
        "COLON" = ":",
        "EQUALS" = "=",
        "AT" = "@",
        "BRACKET_L" = "[",
        "BRACKET_R" = "]",
        "BRACE_L" = "{",
        "PIPE" = "|",
        "BRACE_R" = "}",
        "NAME" = "Name",
        "INT" = "Int",
        "FLOAT" = "Float",
        "STRING" = "String",
        "BLOCK_STRING" = "BlockString",
        "COMMENT" = "Comment"
    };

    variables.DirectiveLocation = {
        // Request Definitions
        QUERY = "QUERY",
        MUTATION = "MUTATION",
        SUBSCRIPTION = "SUBSCRIPTION",
        FIELD = "FIELD",
        FRAGMENT_DEFINITION = "FRAGMENT_DEFINITION",
        FRAGMENT_SPREAD = "FRAGMENT_SPREAD",
        INLINE_FRAGMENT = "INLINE_FRAGMENT",
        // Type System Definitions
        SCHEMA = "SCHEMA",
        SCALAR = "SCALAR",
        OBJECT = "OBJECT",
        FIELD_DEFINITION = "FIELD_DEFINITION",
        ARGUMENT_DEFINITION = "ARGUMENT_DEFINITION",
        INTERFACE_TYPE = "INTERFACE_TYPE",
        UNION = "UNION",
        ENUM = "ENUM",
        ENUM_VALUE = "ENUM_VALUE",
        INPUT_OBJECT = "INPUT_OBJECT",
        INPUT_FIELD_DEFINITION = "INPUT_FIELD_DEFINITION"
    };

    function init() {
        return this;
    }

    function parse( source ) {
        if ( isSimpleValue( source ) ) {
            source = new Source( source );
        }

        if ( ! isInstanceOf( source, "Source" ) ) {
            throw(
                type = "CFGraphQLError",
                message = "Must provide Source. Received: #serializeJSON( source )#"
            );
        }

        var lexer = new Lexer( source );
        return parseDocument( lexer );
    }

    function parseValue( source ) {
        if ( isSimpleValue( source ) ) {
            source = new Source( source );
        }
        var lexer = new Lexer( source );
        expect( lexer, TokenKind,SOF );
        var value = parseValueLiteral( lexer, false );
        expect( lexer, TokenKind.EOF );
        return value;
    }

    function parseType( source ) {
        if ( isSimpleValue( source ) ) {
            source = new Source( source );
        }
        var lexer = new Lexer( source );
        expect( lexer, TokenKind,SOF );
        var type = parseTypeReference( lexer );
        expect( lexer, TokenKind.EOF );
        return type;
    }

    private function parseName( lexer ) {
        var token = expect( lexer, "Name" );
        return {
            "kind" = "Name",
            "value" = token.getValue(),
            "loc" = loc( lexer, token )
        };
    }

    private function parseDocument( lexer ) {
        var start = lexer.getToken();
        expect( lexer, TokenKind.SOF );
        var definitions = [];
        do {
            arrayAppend( definitions, parseDefinition( lexer ) );
        } while ( ! skip( lexer, TokenKind.EOF ) );

        return {
            "kind" = "Document",
            "definitions" = definitions,
            "loc" = loc( lexer, start )
        };
    }

    private function parseDefinition( lexer ) {
        if ( peek( lexer, "Name" ) ) {
            switch ( lexer.getToken().getValue() ) {
                case "query":
                case "mutation":
                case "subscription":
                case "fragment":
                    return parseExecutableDefinition( lexer );
                case "schema":
                case "scalar":
                case "type":
                case "interface":
                case "union":
                case "enum":
                case "input":
                case "directive":
                    return parseTypeSystemDefinition( lexer );
                case "extend":
                    return parseTypeSystemExtension( lexer );
            }
        }
        else if ( peek( lexer, "{" ) ) {
            return parseExecutableDefinition( lexer );
        }
        else if ( peekDescription( lexer ) ) {
            return parseTypeSystemExtension( lexer );
        }

        throwUnexpected( lexer.getToken() );
    }

    private function parseExecutableDefinition( lexer ) {
        if ( peek( lexer, "Name" ) ) {
            switch ( lexer.getToken().getValue() ) {
                case "query":
                case "mutation":
                case "subscription":
                    return parseOperationDefinition( lexer );
                case "fragment":
                    return parseFragmentDefinition( lexer );
            }
        }
        else if ( peek( lexer, "{" ) ) {
            return parseOperationDefinition( lexer );
        }

        throwUnexpected( lexer.getToken() );
    }

    private function parseOperationDefinition( lexer ) {
        var start = lexer.getToken();
        if ( peek( lexer, "{" ) ) {
            return {
                "kind" = "OperationDefinition",
                "operation" = "query",
                "name" = "",
                "variableDefinitions" = [],
                "directives" = [],
                "selectionSet" = parseSelectionSet( lexer ),
                "loc" = loc( lexer, start )
            };
        }
        var operation = parseOperationType( lexer );
        var name = "";
        if ( peek( lexer, "Name" ) ) {
            name = parseName( lexer );
        }
        return {
            "kind" = "OperationDefinition",
            "operation" = operation,
            "name" = name,
            "variableDefinitions" = parseVariableDefinitions( lexer ),
            "directives" = parseDirectives( lexer, false ),
            "selectionSet" = parseSelectionSet( lexer ),
            "loc" = loc( lexer, start )
        };
    }

    private function parseOperationType( lexer ) {
        var operationToken = expect( lexer, "Name" );

        switch ( operationToken.getValue() ) {
            case 'query':
                return 'query';
            case 'mutation':
                return 'mutation';
            case 'subscription':
                return 'subscription';
        }

        throwUnexpected( operationToken );
    }

    private function parseVariableDefinitions( lexer ) {
        return peek( lexer, TokenKind.PAREN_L ) ?
            many( lexer, TokenKind.PAREN_L, parseVariableDefinition, TokenKind.PAREN_R ) :
            [];
    }

    private function parseVariableDefinition( lexer ) {
        var start = lexer.getToken();
        var definition = { kind = "VariableDefinition" };
        definition[ "variable" ] = parseVariable( lexer );
        expect( lexer, TokenKind.COLON );
        definition[ "type" ] = parseTypeReference( lexer );
        definition[ "defaultValue" ] = skip( lexer, TokenKind.EQUALS ) ? parseValueLiteral( lexer, true ) : "";
        definition[ "loc" ] = loc( lexer, start );
        return definition;
    }

    private function parseVariable( lexer ) {
        var start = lexer.getToken();
        expect( lexer, "$" );
        return {
            "kind" = "Variable",
            "name" = parseName( lexer ),
            "loc" = loc( lexer, start )
        };
    }

    private function parseSelectionSet( lexer ) {
        var start = lexer.getToken();
        return {
            "kind" = "SelectionSet",
            "selections" = many( lexer, "{", parseSelection, TokenKind.BRACE_R ),
            "loc" = loc( lexer, start )
        };
    }

    private function parseSelection( lexer ) {
        return peek( lexer, TokenKind.SPREAD ) ?
            parseFragment( lexer ) :
            parseField( lexer );
    }

    private function parseField( lexer ) {
        var start = lexer.getToken();

        var nameOrAlias = parseName( lexer );
        var alias = "";
        var name = "";
        if ( skip( lexer, TokenKind.COLON ) ) {
            alias = nameOrAlias;
            name = parseName( lexer );
        }
        else {
            name = nameOrAlias;
        }

        return {
            "kind" = "Field",
            "alias" = alias,
            "name" = name,
            "args" = parseArguments( lexer, false ),
            "directives" = parseDirectives( lexer, false ),
            "selectionSet" = peek( lexer, "{" ) ? parseSelectionSet( lexer ) : [],
            "loc" = loc( lexer, start )
        };
    }

    private function parseArguments( lexer, isConst ) {
        var item = isConst ? parseConstArgument : parseArgument;
        return peek( lexer, TokenKind.PAREN_L ) ?
            many( lexer, TokenKind.PAREN_L, item, TokenKind.PAREN_R ) :
            [];
    }

    private function parseArgument( lexer ) {
        var start = lexer.getToken();
        var arg = { kind = "Argument" };
        arg[ "name" ]  = parseName( lexer );
        expect( lexer, TokenKind.COLON );
        arg[ "value" ] = parseValueLiteral( lexer, false );
        arg[ "loc" ] = loc( lexer, start );
        return arg;
    }

    private function parseConstArgument( lexer ) {
        var start = lexer.getToken();
        var arg = { kind = "Argument" };
        arg[ "name" ] = parseName( lexer );
        expect( lexer, TokenKind.COLON );
        arg[ "value" ] = parseConstValue( lexer, false );
        arg[ "loc" ] = loc( lexer, start );
        return arg;
    }

    private function parseFragment( lexer ) {
        var start = lexer.getToken();
        expect( lexer, TokenKind.SPREAD );
        if ( peek( lexer, "Name" ) && lexer.getToken().getValue() != "on" ) {
            return {
                "kind" = "FragmentSpread",
                "name" = parseFragmentName( lexer ),
                "directives" = parseDirectives( lexer, false ),
                "loc" = loc( lexer, start )
            };
        }
        var inlineFragment = { kind = "InlineFragment" };
        if ( lexer.getToken().getValue() == "on" ) {
            lexer.advance();
            inlineFragment[ "typeCondition" ] = parseNamedType( lexer );
        }
        inlineFragment[ "directives" ] = parseDirectives( lexer, false );
        inlineFragment[ "selectionSet" ] = parseSelectionSet( lexer );
        inlineFragment[ "loc" ] = loc( lexer, start );
        return inlineFragment;
    }

    private function parseFragmentDefinition( lexer ) {
        var start = lexer.getToken();
        expectKeyword( lexer, "fragment" );
        var fragmentDefinition = { kind = "FragmentDefinition" };
        fragmentDefinition[ "name" ] = parseFragmentName( lexer );
        expectKeyword( lexer, "on" );
        fragmentDefinition[ "typeCondition" ] = parseNamedType( lexer );
        fragmentDefinition[ "directives" ] = parseDirectives( lexer, false );
        fragmentDefinition[ "selectionSet" ] = parseSelectionSet( lexer );
        fragmentDefinition[ "loc" ] = loc( lexer, start);
        return fragmentDefinition;
    }

    private function parseFragmentName( lexer ) {
        if ( lexer.getToken().getValue() == "on" ) {
            throwUnexpected( lexer.getToken() );
        }
        return parseName( lexer );
    }

    private function parseValueLiteral( lexer, isConst ) {
        var token = lexer.getToken();
        switch ( token.getKind() ) {
            case "[":
                return parseList( lexer, isConst );
            case "{":
                return parseObject( lexer, isConst );
            case "Int":
                lexer.advance();
                return {
                    "kind" = "Int",
                    "value" = token.getValue(),
                    "loc" = loc( lexer, token )
                };
            case "Float":
                lexer.advance();
                return {
                    "kind" = "Float",
                    "value" = token.getValue(),
                    "loc" = loc( lexer, token )
                };
            case "String":
            case "BlockString":
                return parseStringLiteral( lexer );
            case "Name":
                if ( token.getValue() == "true" || token.getValue() == "false" ) {
                    lexer.advance();
                    return {
                        "kind" = "Boolean",
                        "value" = token.getValue() == "true",
                        "loc" = loc( lexer, token )
                    };
                }
                else if ( isNull( token.getValue() ) ) {
                    lexer.advance();
                    return {
                        "kind" = "NullValue",
                        "loc" = loc( lexer, token )
                    };
                }
                lexer.advance();
                return {
                    "kind" = "Enum",
                    "value" = token.getValue(),
                    "loc" = loc( lexer, token )
                };
            case "$":
                if ( ! isConst ) {
                    return parseVariable( lexer );
                }
                break;
        }

        throwUnexpected( token );
    }

    private function parseStringLiteral( lexer ) {
        var token = lexer.getToken();
        lexer.advance();
        return {
            "kind" = "String",
            "value" = token.getValue(),
            "block" = token.getKind() == "BlockString",
            "loc" = loc( lexer, token )
        };
    }

    function parseConstValue( lexer ) {
        return parseValueLiteral( lexer, true );
    }

    private function parseValueValue( lexer ) {
        return parseValueLiteral( lexer, false );
    }

    private function parseList( lexer, isConst ) {
        var start = lexer.getToken();
        var item = isConst ? parseConstValue : parseValueValue;
        return {
            "kind" = "List",
            "values" = any( lexer, "[", item, TokenKind.BRACKET_R ),
            "loc" = loc( lexer, start )
        };
    }

    private function parseObject( lexer, isConst ) {
        var start = lexer.getToken();
        expect( lexer, "{" );
        var fields = [];
        while( ! skip( lexer, TokenKind.BRACE_R ) ) {
            arrayAppend( fields, parseObjectField( lexer, isConst ) );
        }
        return {
            "kind" = "Object",
            "fields" = fields,
            "loc" = loc( lexer, start )
        };
    }

    private function parseObjectField( lexer, isConst ) {
        var start = lexer.getToken();
        var objectField = { "kind" = "ObjectField" };
        objectField[ "name" ] = parseName( lexer );
        expect( lexer, TokenKind.COLON );
        objectField[ "value" ] = parseValueLiteral( lexer, isConst );
        objectField[ "loc" ] = loc( lexer, start );
        return objectField;
    }

    private function parseDirectives( lexer, isConst ) {
        var directives = [];
        while( peek( lexer, TokenKind.AT ) ) {
            arrayAppend( directives, parseDirective( lexer, isConst ) );
        }
        return directives;
    }

    private function parseDirective( lexer, isConst ) {
        var start = lexer.getToken();
        expect( lexer, TokenKind.AT );
        return {
            "kind" = "Directive",
            "name" = parseName( lexer ),
            "args" = parseArguments( lexer, isConst ),
            "loc" = loc( lexer, start )
        };
    }

    function parseTypeReference( lexer ) {
        var start = lexer.getToken();
        var type = "";
        if ( skip( lexer, "[" ) ) {
            type = parseTypeReference( lexer );
            expect( lexer, TokenKind.BRACKET_R );
            type = {
                "kind" = "ListType",
                "type" = type,
                "loc" = loc( lexer, start )
            };
        }
        else {
            type = parseNamedType( lexer );
        }

        if ( skip( lexer, TokenKind.BANG ) ) {
            return {
                "kind" = "NonNullType",
                "type" = type,
                "loc" = loc( lexer, start )
            };
        }

        return type;
    }

    function parseNamedType( lexer ) {
        var start = lexer.getToken();
        return {
            "kind" = "NamedType",
            "name" = parseName( lexer ),
            "loc" = loc( lexer, start )
        };
    }

    private function parseTypeSystemDefinition( lexer ) {
        var keywordToken = peekDescription( lexer ) ? lexer.lookahead() : lexer.getToken();

        if ( keywordToken.getKind() == "Name" ) {
            switch ( keywordToken.getValue() ) {
                case "schema":
                    return parseSchemaDefinition( lexer );
                case "scalar":
                    return parseScalarTypeDefinition( lexer );
                case "type":
                    return parseObjectTypeDefinition( lexer );
                case "interface":
                    return parseInterfaceTypeDefinition( lexer );
                case "union":
                    return parseUnionTypeDefinition( lexer );
                case "enum":
                    return parseEnumTypeDefinition( lexer );
                case "input":
                    return parseInputObjectTypeDefinition( lexer );
                case "directive":
                    return parseDirectiveDefinition( lexer );
            }
        }

        throwUnexpected( keywordToken );
    }

    private function peekDescription( lexer ) {
        return peek( lexer, "String" ) || peek( lexer, "BlockString" );
    }

    private function parseDescription( lexer ) {
        if ( peekDescription( lexer ) ) {
            return parseStringLiteral( lexer );
        }
    }

    private function parseSchemaDefinition( lexer ) {
        var start = lexer.getToken();
        expectKeyword( lexer, "schema" );
        var directives = parseDirectives( lexer, true );
        var operationTypes = many(
            lexer,
            "{",
            parseOperationTypeDefinition,
            TokenKind.BRACE_R
        );
        return {
            "kind" = "SchemaDefinition",
            "directives" = directives,
            "operationTypes" = operationTypes,
            "loc" = loc( lexer, start )
        };
    }

    private function parseOperationTypeDefinition( lexer ) {
        var start = lexer.getToken();
        var operation = parseOperationType( lexer );
        expect( lexer, TokenKind.COLON );
        var type = parseNamedType( lexer );
        return {
            "kind" = "OperationTypeDefinition",
            "operation" = operation,
            "type" = type,
            "loc" = loc( lexer, start )
        };
    }

    private function parseScalarTypeDefinition( lexer ) {
        var start = lexer.getToken();
        var description = parseDescription( lexer );
        expectKeyword( lexer, "scalar" );
        var name = parseName( lexer );
        var directives = parseDirectives( lexer, true );
        return {
            "kind" = "ScalarTypeDefinition",
            "description" = description,
            "name" = name,
            "directives" = directives,
            "loc" = loc( lexer, start )
        };
    }

    function parseObjectTypeDefinition( lexer ) {
        var start = lexer.getToken();
        var description = parseDescription( lexer );
        expectKeyword( lexer, "type" );
        var name = parseName( lexer );
        var interfaces = parseImplementsInterfaces( lexer );
        var directives = parseDirectives( lexer, true );
        var fields = parseFieldsDefinition( lexer );
        return {
            "kind" = "ObjectTypeDefinition",
            "description" = description,
            "name" = name,
            "interfaces" = interfaces,
            "directives" = directives,
            "fields" = fields,
            "loc" = loc( lexer, start )
        };
    }

    private function parseImplementsInterfaces( lexer ) {
        var types = [];
        if ( lexer.getToken().getValue() == "implements" ) {
            lexer.advance();
            skip( lexer, TokenKind.AMP );
            do {
                arrayAppend( types, parseNamedType( lexer ) );
            } while ( skip( lexer, TokenKind.AMP ) );
        }
        return types;
    }

    private function parseFieldsDefinition( lexer ) {
        return peek( lexer, "{" ) ?
            many( lexer, "{", parseFieldDefinition, TokenKind.BRACE_R ) :
            [];
    }

    private function parseFieldDefinition( lexer ) {
        var start = lexer.getToken();
        var description = parseDescription( lexer );
        var name = parseName( lexer );
        var args = parseArgumentDefs( lexer );
        expect( lexer, TokenKind.COLON );
        var type = parseTypeReference( lexer );
        var directives = parseDirectives( lexer, true );
        return {
            "kind" = "FieldDefinition",
            "description" = description,
            "name" = name,
            "args" = args,
            "type" = type,
            "directives" = directives,
            "loc" = loc( lexer, start )
        };
    }

    private function parseArgumentDefs( lexer ) {
        if ( ! peek( lexer, TokenKind.PAREN_L ) ) {
            return [];
        }
        return many( lexer, TokenKind.PAREN_L, parseInputValueDef, TokenKind.PAREN_R );
    }

    private function parseInputValueDef( lexer ) {
        var start = lexer.getToken();
        var description = parseDescription( lexer );
        var name = parseName( lexer );
        expect( lexer, TokenKind.COLON );
        var type = parseTypeReference( lexer );
        var defaultValue = "";
        if ( skip( lexer, TokenKind.EQUALS ) ) {
            defaultValue = parseConstValue( lexer );
        }
        var directives = parseDirectives( lexer, true );
        return {
            "kind" = "InputValueDefinition",
            "description" = description,
            "name" = name,
            "type" = type,
            "defaultValue" = defaultValue,
            "directives" = directives,
            "loc" = loc(lexer, start)
        };
    }

    private function parseInterfaceTypeDefinition( lexer ) {
        var start = lexer.getToken();
        var description = parseDescription( lexer );
        expectKeyword( lexer, "interface" );
        var name = parseName( lexer );
        var directives = parseDirectives( lexer, true );
        var fields = parseFieldsDefinition( lexer );
        return {
            "kind" = "InterfaceTypeDefinition",
            "description" = description,
            "name" = name,
            "directives" = directives,
            "fields" = fields,
            "loc" = loc(lexer, start)
        };
    }

    private function parseUnionTypeDefinition( lexer ) {
        var start = lexer.getToken();
        var description = parseDescription( lexer );
        expectKeyword( lexer, "union" );
        var name = parseName( lexer );
        var directives = parseDirectives( lexer, true );
        var types = parseUnionMemberTypes( lexer );
        return {
            "kind" = "UnionTypeDefinition",
            "description" = description,
            "name" = name,
            "directives" = directives,
            "types" = types,
            "loc" = loc(lexer, start)
        };
    }

    private function parseUnionMemberTypes( lexer ) {
        var types = [];
        if ( skip( lexer, TokenKind.EQUALS ) ) {
            skip( lexer, TokenKind.PIPE );
            do {
                arrayAppend( types, parseNamedType( lexer ) );
            } while ( skip( lexer, TokenKind.PIPE ) );
        }
        return types;
    }

    private function parseEnumTypeDefinition( lexer ) {
        var start = lexer.getToken();
        var description = parseDescription( lexer );
        expectKeyword( lexer, "enum" );
        var name = parseName( lexer );
        var directives = parseDirectives( lexer, true );
        var values = parseEnumValuesDefinition( lexer );
        return {
            "kind" = "EnumTypeDefinition",
            "description" = description,
            "name" = name,
            "directives" = directives,
            "values" = values,
            "loc" = loc(lexer, start)
        };
    }

    private function parseEnumValuesDefinition( lexer ) {
        return peek( lexer, "{" ) ?
            many( lexer, "{", parseEnumValueDefinition, TokenKind.BRACE_R ) :
            [];
    }

    private function parseEnumValueDefinition( lexer ) {
        var start = lexer.getToken();
        var description = parseDescription( lexer );
        var name = parseName( lexer );
        var directives = parseDirectives( lexer, true );
        return {
            "kind" = "EnumValueDefinition",
            "description" = description,
            "name" = name,
            "directives" = directives,
            "loc" = loc(lexer, start)
        };
    }

    private function parseInputObjectTypeDefinition( lexer ) {
        var start = lexer.getToken();
        var description = parseDescription( lexer );
        expectKeyword( lexer, "input" );
        var name = parseName( lexer );
        var directives = parseDirectives( lexer, true );
        var fields = parseInputFieldsDefinition( lexer );
        return {
            "kind" = "InputObjectTypeDefinition",
            "description" = description,
            "name" = name,
            "directives" = directives,
            "fields" = fields,
            "loc" = loc(lexer, start)
        };
    }

    private function parseInputFieldsDefinition( lexer ) {
        return peek( lexer, "{" ) ?
            many( lexer, "{", parseInputValueDef, TokenKind.BRACE_R ) :
            [];
    }

    private function parseTypeSystemExtension( lexer ) {
        var keywordToken = lexer.lookahead();

        if ( keywordToken.getKind() == "Name" ) {
            switch( keywordToken.getValue() ) {
                case "schema":
                    return parseSchemaExtension( lexer );
                case "scalar":
                    return parseScalarTypeExtension( lexer );
                case "type":
                    return parseObjectTypeExtension( lexer );
                case "interface":
                    return parseInterfaceTypeExtension( lexer );
                case "union":
                    return parseUnionTypeExtension( lexer );
                case "enum":
                    return parseEnumTypeExtension( lexer );
                case "input":
                    return parseInputObjectTypeExtension( lexer );
            }
        }

        throwUnexpected( keywordToken );
    }

    private function parseSchemaExtension( lexer ) {
        var start = lexer.getToken();

        expectKeyword( lexer, "extend" );
        expectKeyword( lexer, "schema" );

        var directives = parseDirectives( lexer, true );
        var operationTypes = peek( lexer, "{" ) ?
            many( lexer, "{", parseOperationTypeDefinition, TokenKind.BRACE_R ) :
            [];

        if ( arrayIsEmpty( directives ) && arrayIsEmpty( operationTypes ) ) {
            throwUnexpected( start );
        }

        return {
            "kind" = "SchemaExtension",
            "directives" = directives,
            "operationTypes" = operationTypes,
            "loc" = loc( lexer, start )
        };
    }

    private function parseScalarTypeExtension( lexer ) {
        var start = lexer.getToken();

        expectKeyword( lexer, "extend" );
        expectKeyword( lexer, "scalar" );

        var name = parseName( lexer );
        var directives = parseDirectives( lexer, true );

        if ( arrayIsEmpty( directives ) ) {
            throwUnexpected( start );
        }

        return {
            "kind" = "ScalarTypeExtension",
            "name" = name,
            "directives" = directives,
            "loc" = loc( lexer, start )
        };
    }

    private function parseObjectTypeExtension( lexer ) {
        var start = lexer.getToken();

        expectKeyword( lexer, "extend" );
        expectKeyword( lexer, "type" );

        var name = parseName( lexer );
        var interfaces = parseImplementsInterfaces( lexer );
        var directives = parseDirectives( lexer, true );
        var fields = parseFieldsDefinition( lexer );

        if ( arrayIsEmpty( interfaces ) && arrayIsEmpty( directives ) && arrayIsEmpty( fields ) ) {
            throwUnexpected( start );
        }

        return {
            "kind" = "ObjectTypeExtension",
            "name" = name,
            "interfaces" = interfaces,
            "directives" = directives,
            "fields" = fields,
            "loc" = loc( lexer, start )
        };
    }

    private function parseInterfaceTypeExtension( lexer ) {
        var start = lexer.getToken();

        expectKeyword( lexer, "extend" );
        expectKeyword( lexer, "interface" );

        var name = parseName( lexer );
        var directives = parseDirectives( lexer, true );
        var fields = parseFieldsDefinition( lexer );

        if ( arrayIsEmpty( directives ) && arrayIsEmpty( fields ) ) {
            throwUnexpected( start );
        }

        return {
            "kind" = "InterfaceTypeExtension",
            "name" = name,
            "directives" = directives,
            "fields" = fields,
            "loc" = loc( lexer, start )
        };
    }

    private function parseUnionTypeExtension( lexer ) {
        var start = lexer.getToken();

        expectKeyword( lexer, "extend" );
        expectKeyword( lexer, "union" );

        var name = parseName( lexer );
        var directives = parseDirectives( lexer, true );
        var types = parseUnionMemberTypes( lexer );

        if ( arrayIsEmpty( directives ) && arrayIsEmpty( types ) ) {
            throwUnexpected( start );
        }

        return {
            "kind" = "UnionTypeExtension",
            "name" = name,
            "directives" = directives,
            "types" = types,
            "loc" = loc( lexer, start )
        };
    }

    private function parseEnumTypeExtension( lexer ) {
        var start = lexer.getToken();

        expectKeyword( lexer, "extend" );
        expectKeyword( lexer, "enum" );

        var name = parseName( lexer );
        var directives = parseDirectives( lexer, true );
        var values = parseEnumValuesDefinition( lexer );

        if ( arrayIsEmpty( directives ) && arrayIsEmpty( values ) ) {
            throwUnexpected( start );
        }

        return {
            "kind" = "EnumTypeExtension",
            "name" = name,
            "directives" = directives,
            "values" = values,
            "loc" = loc( lexer, start )
        };
    }

    private function parseInputObjectTypeExtension( lexer ) {
        var start = lexer.getToken();

        expectKeyword( lexer, "extend" );
        expectKeyword( lexer, "input" );

        var name = parseName( lexer );
        var interfaces = parseImplementsInterfaces( lexer );
        var directives = parseDirectives( lexer, true );
        var fields = parseInputFieldsDefinition( lexer );

        if ( arrayIsEmpty( directives ) && arrayIsEmpty( fields ) ) {
            throwUnexpected( start );
        }

        return {
            "kind" = "InputObjectTypeExtension",
            "name" = name,
            "directives" = directives,
            "fields" = fields,
            "loc" = loc( lexer, start )
        };
    }

    private function parseDirectiveDefinition( lexer ) {
        var start = lexer.getToken();
        var description = parseDescription( lexer );
        expectKeyword( lexer, "directive" );
        expect( lexer, TokenKind.AT );
        var name = parseName( lexer );
        var args = parseArgumentDefs( lexer );
        expectKeyword( lexer, "on" );
        var locations = parseDirectiveLocations( lexer );
        return {
            "kind" = "DirectiveDefinition",
            "description" = description,
            "name" = name,
            "args" = args,
            "locations" = locations,
            "loc" = loc( lexer, start )
        };
    }

    private function parseDirectiveLocations( lexer ) {
        skip( lexer, TokenKind.PIPE );
        var locations = [];
        do {
            arrayAppend( locations, parseDirectiveLocation( lexer ) );
        } while( skip( lexer, TokenKind.PIPE ) );
        return locations;
    }

    private function parseDirectiveLocation( lexer ) {
        var start = lexer.getToken();
        var name = parseName( lexer );
        if ( structKeyExists( variables.DirectiveLocation, name.getValue() ) ) {
            return name;
        }
        throwUnexpected( start );
    }

    private function loc( lexer, startToken ) {
        return {
            "start" = startToken.getStart(),
            "end" = lexer.getLastToken().getEnd()
        };
    }

    private function peek( lexer, kind ) {
        return lexer.getToken().isKind( kind );
    }

    private function skip( lexer, kind ) {
        var match = lexer.getToken().isKind( kind );
        if ( match ) {
            lexer.advance();
        }
        return match;
    }

    private function expect( lexer, kind ) {
        var token = lexer.getToken();

        if ( ! isNull( token ) && token.isKind( kind ) ) {
            lexer.advance();
            return token;
        }

        throw(
            type = "CFGraphQLSyntaxError",
            message = "Expected #kind#, found #isNull( token ) ? 'null' : token.toString()#",
            detail = "Encountered at #lexer.getLineStart()# in source: #lexer.getSource().getBody()#"
        );
    }

    private function expectKeyword( lexer, value ) {
        var token = lexer.getToken();
        if ( token.isKind( "Name" ) && token.getValue() == value ) {
            lexer.advance();
            return token;
        }

        throw(
            type = "CFGraphQLSyntaxError",
            message = "Expected #value#, found #token.toString()#",
            detail = "Encountered at #lexer.getLineStart()# in source: #lexer.getSource().getBody()#"
        );
    }

    private function throwUnexpected( token ) {
        throw(
            type = "CFGraphQLSyntaxError",
            message = "Unexpected token: #token.toString()#"
        );
    }

    private function any( lexer, openKind, parseFn, closeKind ) {
        expect( lexer, openKind );
        var nodes = [];
        while( ! skip( lexer, closeKind ) ) {
            arrayAppend( nodes, parseFn( lexer ) );
        }
        return nodes;
    }

    private function many( lexer, openKind, parseFn, closeKind ) {
        expect( lexer, openKind );
        var nodes = [ parseFn( lexer ) ];
        while( ! skip( lexer, closeKind ) ) {
            arrayAppend( nodes, parseFn( lexer ) );
        }
        return nodes;
    }

}
