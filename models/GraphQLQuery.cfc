component accessors="true" {

    property name="parser";
    property name="rawQuery";
    property name="document";

    function init( rawQuery, parser = new Language.Parser() ) {
        setParser( parser );
        setRawQuery( rawQuery );
        parseQuery();
        return this;
    }

    private function parseQuery() {
        setDocument( parser.parse( getRawQuery() ) );
    }

}
