component accessors="true" {

    property name="start";
    property name="end";
    property name="startToken";
    property name="endToken";
    property name="source";

    function init( startToken, endToken, source ) {
        setStart( startToken.getStart() );
        setEnd( endToken.getEnd() );
        setStartToken( startToken );
        setEndToken( endToken );
        setSource( source );
        return this;
    }

    function serialize() {
        return {
            "start" = getStart(),
            "end" = getEnd()
        };
    }

}
