component {

    property name="graphql" inject="Client@cfgraphql";

    function index( event, rc, prc ) {
        event.renderData(
            format = "json",
            data = graphql.execute( event.getHTTPContent() )
        );
    }

}
