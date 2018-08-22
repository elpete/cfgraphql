component accessors="true" {

    property name="schema";
    property name="fragments";
    property name="rootValue";
    property name="contextValue";
    property name="operation";
    property name="variableValues";
    property name="fieldResolver";
    property name="errors";

    function init(
        schema,
        document,
        rootValue,
        contextValue,
        variableValues,
        operationName = "",
        fieldResolver = variables.defaultFieldResolver
    ) {
        setSchema( schema );
        setDocument( document );
        setRootValue( isNull( rootValue ) ? javacast( "null", "" ) : rootValue );
        setContextValue( isNull( contextValue ) ? javacast( "null", "" ) : contextValue );
        setOperationName( operationName );
        setFieldResolver( fieldResolver );

        parseExecutionContext( variableValues );

        return this;
    }

    private function parseExecutionContext( rawVariableValues ) {
        var errors = [];
        var operation = javacast( "null", "" );
        var hasMultipleAssumedOperations = false;
        var fragments = {};
        getDocument().definitions.each( function( definition ) {
            switch ( definition.kind ) {
                case "OperationDefinition":
                    if ( getOperationName() == "" && ! isNull( operation ) ) {
                        hasMultipleAssumedOperations = true;
                    }
                    else if (
                        getOperationName() == "" ||
                        ( definition.keyExists( "name" ) && definition.name.value == getOperationName() )
                    ) {
                        operation = definition;
                    }
                    break;
                case "FragmentDefinition":
                    fragments[ definition.name.value ] = definition;
                    break;
            }
        } );

        if ( isNull( operation ) ) {
            if ( getOperationName() ) {
                errors.append( "Unknown operation named #operationName#" );
            }
            else {
                errors.append( "Must provide an operation" );
            }
        }
        else if ( hasMultipleAssumedOperations ) {
            errors.append( "Must provide operation name if query contains multiple operations." );
        }

        var variableValues = {};
        if ( ! isNull( operation ) ) {
            var coercedVariableValues = parseVariableValues(
                operation.variableDefinitions ?: [],
                rawVariableValues ?: {}
            );
        }
    }

    private function parseVariableValues( variableDefinitions = [], rawVariableValues = {} ) {
        var errors = [];
        var coercedValues = {};
        variableDefinitions.each( function( variableDefinition ) {
            var varName = variableDefinition.variable.name.value;
            var varType = typeFromAST( variableDefinition.type );
            if ( ! isInputType( varType ) ) {
                errors.append(
                    "Variable $#varName# expected value of type #variableDefinition.type# which cannot be used as an input type."
                );
            }
        } );
    }

    private function typeFromAST( typeNode ) {
        if ( typeNode.kind == "ListType" ) {
            var innerType = typeFromAST( typeNode.type );
            return GraphQLList( innerType );
        }

        if ( typeNode.kind == "NonNullType" ) {
            var innerType = typeFromAST( typeNode.type );
            return GraphQLNonNull( innerType );
        }

        if ( typeNode.kind == "NamedType" ) {
            return getSchema().getType( typeNode.name.value );
        }

        throw(
            type = "CFGraphQLExecutionError",
            message = "Unexpected type kind: #typeNode.kind#."
        );
    }

    private function defaultFieldResolver() {

    }

}
