component extends="testbox.system.BaseSpec" {

    function beforeAll() {
        variables.visitor = new models.Language.Visitor();
        variables.parser = new models.Language.Parser();
    }

    function run() {
        describe( "Visitor", function() {
            it( "validates path argument", function() {
                var visited = [];
                var ast = parser.parse( "{ a }" );
                visitor.visit( ast, {
                    enter = function( node, key, parent, path, ancestors ) {
                        // checkVisitorFnArgs( ast, arguments );
                        writeDump( var = path );
                        visited.append( [ "enter", duplicate( path ) ] );
                    },

                    leave = function( node, key, parent, path, ancestors ) {
                        // checkVisitorFnArgs( ast, arguments );
                        visited.append( [ "leave", duplicate( path ) ] );
                    }
                });

                expect( visited[ 3 ] ).toBe(
                    // [ "enter", [] ]
                    // [ "enter", [ "definitions", 1 ] ]
                    [ "enter", [ "definitions", 1, "selectionSet" ] ]
                    // [ "enter", [ "definitions", 1, "selectionSet", "selections", 1 ] ]
                    // [ "enter", [ "definitions", 1, "selectionSet", "selections", 1, "name" ] ]
                    // [ "leave", [ "definitions", 1, "selectionSet", "selections", 1, "name" ] ]
                    // [ "leave", [ "definitions", 1, "selectionSet", "selections", 1 ] ]
                    // [ "leave", [ "definitions", 1, "selectionSet" ] ]
                    // [ "leave", [ "definitions", 1 ] ]
                    // [ "leave", [] ]
                );
            } );
        } );
    }

    private function checkVisitorFnArgs( ast, args, isEdited = false ) {
        expect( args.node ).toBeStruct();

        var isRoot = isNull( args.key );
        if ( isRoot ) {
            if ( ! isEdited ) {
                expect( args.node ).toBe( ast );
            }
            expect( isNull( args.parent ) ).toBeTrue( "parent should be null" );
            expect( args.path ).toBe( [] );
            expect( args.ancestors ).toBe( [] );
            return;
        }

        expect( isValid( "string", args.key ) || isValid( "numeric", args.key ) )
            .toBeTrue( "key should be a string or number" );
        // expect( args.parent ).toHaveKey( args.key );

        expect( args.path ).toBeArray();
        expect( args.path[ arrayLen( args.path ) ] ).toBe( args.key );

        expect( args.ancestors ).toBeArray();
        // expect( args.ancestors ).toHaveLength( arrayLen( args.path ) - 1 );

        if ( ! isEdited ) {
            expect( args.parent[ args.key ] ).toBe( args.node );
            // expect( getNodeByPath( args.ast, args.path ) ).toBe( node );
            // for ( var i = 1; i < arrayLen( ancestors ); i++ ) {

            // }
        }
    }

}
