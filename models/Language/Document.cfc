component accessors="true" {

    property name="definitions";
    property name="loc";

    function init( definitions, loc ) {
        setDefinitions( definitions );
        setLoc( loc );
        return this;
    }

    function serialize() {
        return {
            "kind" = "Document",
            "definitions" = getDefinitions().map( function( definition ) {
                return definition.serialize();
            } ),
            "loc" = getLoc().serialize()
        };
    }

}
