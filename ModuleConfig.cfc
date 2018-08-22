component {

    this.name = "cfgraphql";

    function configure() {
        settings = {
            rootResolver = "Query";
        };
    }

    function onLoad() {
        binder.map( "Client@cfgraphql" )
            .to( "#moduleMapping#.models.GraphQLClient" )
            .initArg( name = "rootResolver", ref = settings.rootResolver )
            .asSingleton();
    }

}
