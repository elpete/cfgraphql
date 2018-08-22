component accessors="true" {

    property name="schema";

    function init( schema, rootResolver ) {
        setSchema( schema );
        return this;
    }

    function execute( rawQuery ) {
        var parsedQuery = new GraphQLQuery( rawQuery );
        var executionContext = new GraphQLExecutionContext(
            getSchema(),
            parsedQuery.getDocument()
        );

        return {
            "data" = {
                "hero" = {
                    "name" = "R2-D2"
                }
            }
        };
    }

}
