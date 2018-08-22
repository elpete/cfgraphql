component accessors="true" {

    property name="source";
    property name="lastToken";
    property name="token";
    property name="line";
    property name="lineStart";

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

    function init( source ) {
        variables.blockStringParser = new BlockStringParser();
        var startOfFileToken = createToken( TokenKind.SOF, 1, 1, 1, 1 );
        setSource( source );
        setLastToken( startOfFileToken );
        setToken( startOfFileToken );
        setLine( 1 );
        setLineStart( 1 );
        return this;
    }

    function createToken(
        kind,
        start,
        end,
        line,
        column,
        prev,
        value
    ) {
        return new Token( argumentCollection = arguments );
    }

    function advance() {
        setLastToken( this.getToken() );
        var token = lookahead();
        setToken( token );
        return token;
    }

    function lookahead() {
        var token = this.getToken();
        if ( token.getKind() != TokenKind.EOF ) {
            do {
                token = token.hasNext() ? token.getNext() : readToken( token );
            } while ( token.getKind() == TokenKind.COMMENT );
        }
        return token;
    }

    private function readToken( prev ) {
        var source = getSource();
        var body = source.getBody();
        var bodyLength = body.len();

        var pos = positionAfterWhitespace( body, prev.getEnd() );
        var line = getLine();
        var col = 1 + pos - getLineStart();

        if ( pos > bodyLength ) {
            return createToken( TokenKind.EOF, bodyLength, bodyLength, line, col, prev );
        }

        var code = charCodeAt( body, pos );

        switch ( code ) {
            // !
            case 33:
                return createToken( TokenKind.BANG, pos, pos + 1, line, col, prev );
            // #
            case 35:
                return readComment( source, pos, line, col, prev );
            // $
            case 36:
                return createToken( TokenKind.DOLLAR, pos, pos + 1, line, col, prev );
            // &
            case 38:
                return createToken( TokenKind.AMP, pos, pos + 1, line, col, prev );
            // (
            case 40:
                return createToken( TokenKind.PAREN_L, pos, pos + 1, line, col, prev );
            // )
            case 41:
                return createToken( TokenKind.PAREN_R, pos, pos + 1, line, col, prev );
            // .
            case 46:
                if ( charCodeAt( body, pos + 1 ) == 46 && charCodeAt( body, pos + 2 ) == 46 ) {
                    return createToken( TokenKind.SPREAD, pos, pos + 3, line, col, prev );
                }
                break;
            // :
            case 58:
                return createToken( TokenKind.COLON, pos, pos + 1, line, col, prev );
            // =
            case 61:
                return createToken( TokenKind.EQUALS, pos, pos + 1, line, col, prev );
            // @
            case 64:
                return createToken( TokenKind.AT, pos, pos + 1, line, col, prev );
            // [
            case 91:
                return createToken( TokenKind.BRACKET_L, pos, pos + 1, line, col, prev );
            // ]
            case 93:
                return createToken( TokenKind.BRACKET_R, pos, pos + 1, line, col, prev );
            // {
            case 123:
                return createToken( TokenKind.BRACE_L, pos, pos + 1, line, col, prev );
            // |
            case 124:
                return createToken( TokenKind.PIPE, pos, pos + 1, line, col, prev );
            // }
            case 125:
                return createToken( TokenKind.BRACE_R, pos, pos + 1, line, col, prev );
            // A-Z _ a-z
            case 65:
            case 66:
            case 67:
            case 68:
            case 69:
            case 70:
            case 71:
            case 72:
            case 73:
            case 74:
            case 75:
            case 76:
            case 77:
            case 78:
            case 79:
            case 80:
            case 81:
            case 82:
            case 83:
            case 84:
            case 85:
            case 86:
            case 87:
            case 88:
            case 89:
            case 90:
            case 95:
            case 97:
            case 98:
            case 99:
            case 100:
            case 101:
            case 102:
            case 103:
            case 104:
            case 105:
            case 106:
            case 107:
            case 108:
            case 109:
            case 110:
            case 111:
            case 112:
            case 113:
            case 114:
            case 115:
            case 116:
            case 117:
            case 118:
            case 119:
            case 120:
            case 121:
            case 122:
                return readName( source, pos, line, col, prev );
            // - 0-9
            case 45:
            case 48:
            case 49:
            case 50:
            case 51:
            case 52:
            case 53:
            case 54:
            case 55:
            case 56:
            case 57:
                return readNumber( source, pos, code, line, col, prev );
            // "
            case 34:
                if ( charCodeAt( body, pos + 1 ) == 34 && charCodeAt( body, pos + 2 ) == 34 ) {
                    return readBlockString( source, pos, line, col, prev );
                }
                return readString( source, pos, line, col, prev );
        }

        throw(
            type = "CFGraphQLSyntaxError",
            message = unexpectedCharacterMessage( code, pos ),
            detail = "Body: #source.getBody()#"
        );
    }

    private function positionAfterWhitespace( body, startPosition ) {
        var bodyLength = body.len();
        var position = startPosition;

        while( position <= bodyLength ) {
            var code = charCodeAt( body, position );

            // tab | space | comma
            if ( code == 9 || code == 32 || code == 44 ) {
                position++;
            }
            // new line
            else if ( code == 10 ) {
                position++;
                setLine( getLine() + 1 );
                setLineStart( position );
            }
            // line feed
            else if ( code == 13 ) {
                // carriage return
                if ( charCodeAt( body, position + 1 ) == 10 ) {
                    position += 2;
                }
                else {
                    position++;
                }
                setLine( getLine() + 1 );
                setLineStart( position );
            }
            else {
                break;
            }
        }
        return position;
    }

    private function charCodeAt( str, position ) {
        var strArray = listToArray( str, "" );
        return asc( strArray[ position ] );
    }

    private function unexpectedCharacterMessage( code, pos ) {
        if ( code == 39 ) { // '
            return "Unexpected single quote character ('), did you mean to use a double quote ("")?";
        }

        return "Cannot parse the unexpected character (#chr( code )# [#code#]) at position #pos#";
    }

    private function readComment( source, start, line, col, prev ) {
        var body = source.getBody();
        var code = "";
        var position = start;

        do {
            position++;
            code = charCodeAt( body, position );
        } while (
            ! isNull( code ) &&
            ( code > 31 || code == 9 )
        );

        return createToken(
            TokenKind.COMMENT,
            start,
            position,
            line,
            col,
            prev,
            mid( body, start + 1, position - start + 1 )
        );
    }

    private function readNumber( source, start, firstCode, line, col, prev ) {
        var body = source.getBody();
        var code = firstCode;
        var position = start;
        var isFloat = false;

        if ( code == 45 ) { // -
            position++;
            code = charCodeAt( body, position );
        }

        if ( code == 48 ) { // 0
            position++;
            code = charCodeAt( body, position );
            if ( code >= 48 && code <= 57 ) {
                throw(
                    type = "CFGraphQLSyntaxError",
                    message = "Invalid number at position #pos# - unexpected digit after 0: #chr( code )#",
                    detail = "Body: #source.getBody()#"
                );
            }
        }
        else {
            position = readDigits( source, position, code );
            code = charCodeAt( body, position );
        }

        if ( code == 46 ) { // .
            isFloat = true;
            position++;
            code = charCodeAt( body, position );
            position = readDigits( source, position, code );
            code = charCodeAt( body, position );
        }

        if ( code == 69 || code == 101 ) { // E e
            isFloat = true;
            position++;
            code = charCodeAt( body, position );
            if ( code == 43 || code == 45 ) { // + -
                position++;
                code = charCodeAt( body, position );
            }
            position = readDigits( source, position, code );
        }

        return createToken(
            isFloat ? TokenKind.FLOAT : TokenKind.INT,
            start,
            position,
            line,
            col,
            prev,
            mid( body, start, position - start )
        );
    }

    private function readDigits( source, start, firstCode ) {
        var body = source.getBody();
        var position = start;
        var code = firstCode;

        if ( code >= 48 && code <= 57 ) { // 0-9
            do {
                position++;
                code = charCodeAt( body, position );
            } while ( code >= 48 && code <= 57 );
            return position;
        }

        throw(
            type = "CFGraphQLSyntaxError",
            message = "Invalid number at position #pos# - expected digit but got: #chr( code )#",
            detail = "Body: #source.getBody()#"
        );
    }

    private function readString( source, start, line, col, prev ) {
        var body = source.getBody();
        var bodyLength = body.len();
        var position = start + 1;
        var chunkStart = position;
        var code = charCodeAt( body, position );
        var value = '';

        while (
            position < bodyLength &&
            code != 10 &&
            code != 13
        ) {
            if ( code == 34 ) { // "
                value &= mid( body, chunkStart + 1, position - chunkStart + 1 );
                return createToken(
                    TokenKind.STRING,
                    start,
                    position + 1,
                    line,
                    col,
                    prev,
                    value
                );
            }

            if ( code < 32 && code != 9 ) {
                throw(
                    type = "CFGraphQLSyntaxError",
                    message = "Invalid character at position #pos#: #chr( code )#",
                    detail = "Body: #source.getBody()#"
                );
            }

            position++;

            if ( code == 92 ) { // \
                value &= mid( body, chunkStart + 1, position - chunkStart );
                code = charCodeAt( body, position );
                switch( code ) {
                    case 34:
                        value &= '"';
                        break;
                    case 47:
                        value &= "/";
                        break;
                    case 92:
                        value &= "\\";
                        break;
                    case 98:
                        value &= "\b";
                        break;
                    case 102:
                        value &= "\f";
                        break;
                    case 110:
                        value &= "\n";
                        break;
                    case 114:
                        value &= "\r";
                        break;
                    case 116:
                        value &= "\t";
                        break;
                    case 117: // u
                        var charCode = inputBaseN(
                            charCodeAt( body, position + 1 ) &
                            charCodeAt( body, position + 2 ) &
                            charCodeAt( body, position + 3 ) &
                            charCodeAt( body, position + 4 ),
                            16
                        );

                        if ( charCode < 0 ) {
                            throw(
                                type = "CFGraphQLSyntaxError",
                                message = "Invalid character escape sequence at position #pos#: u#mid( body, position + 1, 4 )#",
                                detail = "Body: #source.getBody()#"
                            );
                        }

                        value &= chr( charCode );
                        position += 4;
                        break;
                    default:
                        throw(
                            type = "CFGraphQLSyntaxError",
                            message = "Invalid character escape sequence at position #pos#: #chr( code )#",
                            detail = "Body: #source.getBody()#"
                        );
                }

                position++;
                chunkStart = position;
                code = charCodeAt( body, position );
            }

            code = charCodeAt( body, position );
        }

        throw(
            type = "CFGraphQLSyntaxError",
            message = "Unterminated String",
            detail = "Body: #source.getBody()#"
        );
    }

    private function readBlockString( source, start, line, col, prev ) {
        var body = source.getBody();
        var position = start + 3;
        var chunkStart = position;
        var code = charCodeAt( body, position );
        var rawValue = "";

        while ( position < body.len() ) {
            // Closing Triple-Quote (""")
            if (
                code == 34 &&
                charCodeAt( body, position + 1 ) == 34 &&
                charCodeAt( body, position + 2 ) == 34
            ) {
                rawValue &= mid( body, chunkStart + 1, position - chunkStart + 1 );
                return createToken(
                    TokenKind.BLOCK_STRING,
                    start,
                    position + 3,
                    line,
                    col,
                    prev,
                    blockStringParser.parse( rawValue )
                );
            }

            // SourceCharacter
            if (
                code < 32 &&
                code != 9 &&
                code != 10 &&
                code != 13
            ) {
                throw(
                    type = "CFGraphQLSyntaxError",
                    message = "Invalid character at position #pos#: #chr( code )#",
                    detail = "Body: #source.getBody()#"
                );
            }

            // Escape Triple-Quote (""")
            if (
                code == 92 &&
                charCodeAt( body, position + 1 ) == 34 &&
                charCodeAt( body, position + 2 ) == 34 &&
                charCodeAt( body, position + 3 ) == 34
            ) {
                rawValue = mid( body, chunkStart + 1, position - chunkStart ) & '"""';
                position += 4;
                chunkStart = position;
            } else {
                position++;
            }
            code = charCodeAt( body, position );
        }

        throw(
            type = "CFGraphQLSyntaxError",
            message = "Unterminated String",
            detail = "Body: #source.getBody()#"
        );
    }

    private function readName( source, start, line, col, prev ) {
        var body = source.getBody();
        var bodyLength = body.len();
        var position = start + 1;
        var code = charCodeAt( body, position );

        while (
            position != bodyLength &&
            (
                code == 95 || // _
                ( code >= 48 && code <= 57 ) || // 0-9
                ( code >= 65 && code <= 90 ) || // A-Z
                ( code >= 97 && code <= 122 ) // a-z
            )
        ) {
            position++;
            code = charCodeAt( body, position );
        }

        return createToken(
            TokenKind.NAME,
            start,
            position,
            line,
            col,
            prev,
            mid( body, start, position - start )
        );
    }

}
