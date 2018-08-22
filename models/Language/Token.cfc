component accessors="true" {

    property name="kind";
    property name="start";
    property name="end";
    property name="line";
    property name="column";
    property name="value";
    property name="prev";
    property name="next";

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

    function init(
        kind,
        start,
        end,
        line,
        column,
        value = "",
        prev,
        next
    ) {
        setKind( kind );
        setStart( start );
        setEnd( end );
        setLine( line );
        setColumn( column );
        setValue( value );
        setPrev( isNull( prev ) ? javacast( "null", "" ) : prev );
        setNext( isNull( next ) ? javacast( "null", "" ) : next );
        return this;
    }

    function hasNext() {
        return ! isNull( getNext() );
    }

    function isKind( kind ) {
        return getKind() == kind;
    }

    function toString() {
        return isNull( getValue() ) ? getKind() : "#getKind()# #getValue()#";
    }

}
