component extends="testbox.system.BaseSpec" {

    function beforeAll() {
        variables.lineSeparator = createObject( "java", "java.lang.System" ).lineSeparator();
        variables.parser = new models.Language.BlockStringParser();
        return this;
    }

    function run() {
        describe( "Block String Parser", function() {
            it( "removes uniform indentation from a string", function() {
                var rawValue = arrayToList( [
                    "",
                    "    Hello,",
                    "      World!",
                    "",
                    "    Yours,",
                    "      GraphQL."
                ], lineSeparator );

                expect( parser.parse( rawValue ) ).toBe(
                    arrayToList( [ "Hello,", "  World!", "", "Yours,", "  GraphQL." ], lineSeparator )
                );
            } );

            it( "removes empty leading and trailing lines", function() {
                var rawValue = arrayToList( [
                    "",
                    "",
                    "    Hello,",
                    "      World!",
                    "",
                    "    Yours,",
                    "      GraphQL.",
                    "",
                    ""
                ], lineSeparator );
                expect( parser.parse( rawValue ) ).toBe(
                    arrayToList( [ "Hello,", "  World!", "", "Yours,", "  GraphQL." ], lineSeparator )
                );
            } );

            it( "removes blank leading and trailing lines", function() {
                var rawValue = arrayToList( [
                    "  ",
                    "        ",
                    "    Hello,",
                    "      World!",
                    "",
                    "    Yours,",
                    "      GraphQL.",
                    "        ",
                    "  "
                ], lineSeparator );
                expect( parser.parse( rawValue ) ).toBe(
                    arrayToList( [ "Hello,", "  World!", "", "Yours,", "  GraphQL." ], lineSeparator )
                );
            } );

            it( "retains indentation from first line", function() {
                var rawValue = arrayToList( [
                    "    Hello,",
                    "      World!",
                    "",
                    "    Yours,",
                    "      GraphQL."
                ], lineSeparator );
                expect( parser.parse( rawValue ) ).toBe(
                    arrayToList( [ "    Hello,", "  World!", "", "Yours,", "  GraphQL." ], lineSeparator )
                );
            } );

            it( "does not alter trailing spaces", function() {
                var rawValue = arrayToList( [
                    "               ",
                    "    Hello,     ",
                    "      World!   ",
                    "               ",
                    "    Yours,     ",
                    "      GraphQL. ",
                    "               "
                ], lineSeparator );
                expect( parser.parse( rawValue ) ).toBe(
                    arrayToList( [
                        "Hello,     ",
                        "  World!   ",
                        "           ",
                        "Yours,     ",
                        "  GraphQL. "
                    ], lineSeparator )
                );
            } );
        } );
    }

}
