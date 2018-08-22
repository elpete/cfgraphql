component accessors="true" {

    property name="body";
    property name="name";
    property name="locationOffset";

    function init(
        body,
        name = "GraphQL Request",
        locationOffset = { line = 1, column = 1}
    ) {
        setBody( body );
        setName( name );
        setLocationOffset( locationOffset );
        return this;
    }

}
