component {

    function init() {
        variables.separator = createObject( "java", "java.lang.System" ).lineSeparator();
        return this;
    }

    function parse( str ) {
        var lines = javacast( "String", str ).split( "\r\n|[\n\r]" );

        var commonIndent = javacast( "null", "" );
        for ( var i = 2; i <= arrayLen( lines ); i++ ) {
            var line = lines[ i ];
            var indent = leadingWhitespace( line );
            if (
                indent < len( line ) &&
                ( isNull( commonIndent ) || indent < commonIndent )
            ) {
                commonIndent = indent;
                if ( commonIndent == 0 ) {
                    break;
                }
            }
        }

        if ( ! isNull( commonIndent ) ) {
            for ( var i = 2; i <= arrayLen( lines ); i++ ) {
                if ( len( lines[ i ] ) >= commonIndent ) {
                    lines[ i ] = mid( lines[ i ], commonIndent, len( lines[ i ] ) - commonIndent + 1 );
                }
            }
        }

        while( arrayLen( lines ) > 0 && isBlank( lines[ 1 ] ) ) {
            var newLines = [];
            for ( var i = 2; i <= arrayLen( lines ); i++ ) {
                arrayAppend( newLines, lines[ i ] );
            }
            lines = newLines;
        }

        while( arrayLen( lines ) > 0 && isBlank( lines[ arrayLen( lines ) ] ) ) {
            var newLines = [];
            for ( var i = 1; i < arrayLen( lines ); i++ ) {
                arrayAppend( newLines, lines[ i ] );
            }
            lines = newLines;
        }

        return arrayToList( lines, variables.separator );
    }

    private function leadingWhitespace( str ) {
        if ( len( str ) == 0 ) {
            return 0;
        }
        var i = 1;
        var chars = listToArray( str, "" );
        while ( i <= arrayLen( chars ) && ( asc( chars[ i ] ) == 32 || asc( chars[ i ] ) == 9 ) ) {
            i++;
        }
        return i;
    }

    private function isBlank( str ) {
        return leadingWhitespace( str ) >= len( str );
    }

}
