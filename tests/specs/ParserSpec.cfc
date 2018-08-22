component extends="testbox.system.BaseSpec" {

    function beforeAll() {
        variables.parser = new models.Language.Parser();
    }

    function run() {
        describe( "Parser", function() {
            it( "asserts that a source to parse was provided", function() {
                expect( function() {
                    parser.parse();
                } ).toThrow();
            } );

            it( "asserts that a source to parse was provided", function() {
                expect( function() {
                    parser.parse( {} );
                } ).toThrow( regex = "Must provide Source" );
            } );

            it( "parse provides useful errors", function() {
                expect( function() {
                    parser.parse( "{" );
                } ).toThrow( regex = "Expected Name\, found \<EOF\>" );
            } );

            it( "parses variable inline values", function() {
                expect( function() {
                    parser.parse( "{ field(complex: { a: { b: [ $var ] } }) }" );
                } ).notToThrow();
            } );

            it( "parses the kitchen sink", function() {
                var kitchenSink = fileRead( expandPath( "/tests/resources/KitchenSink.graphql" ) );
                parser.parse( kitchenSink );
            } );

            it( "creates an ast", function() {
                var result = parser.parse( arrayToList( [
                    "{",
                    "   node(id: 4) {",
                    "       id,",
                    "       name",
                    "   }",
                    "}"
                ], chr( 10 ) ) );

                expect( result ).toBeStruct();
                expect( result.kind ).toBe( "Document" );
            } );
        } );
    }

}

            //                     expect(toJSONDeep(result)).to.deep.equal({
            //                         kind: Kind.DOCUMENT,
            //                         loc: { start: 0, end: 41 },
            //                         definitions: [
            //                         {
            //                             kind: Kind.OPERATION_DEFINITION,
            //                             loc: { start: 0, end: 40 },
            //                             operation: 'query',
            //                             name: undefined,
            //                             variableDefinitions: [],
            //                             directives: [],
            //                             selectionSet: {
            //                                 kind: Kind.SELECTION_SET,
            //                                 loc: { start: 0, end: 40 },
            //                                 selections: [
            //                                 {
            //                                     kind: Kind.FIELD,
            //                                     loc: { start: 4, end: 38 },
            //                                     alias: undefined,
            //                                     name: {
            //                                         kind: Kind.NAME,
            //                                         loc: { start: 4, end: 8 },
            //                                         value: 'node',
            //                                     },
            //                                     arguments: [
            //                                     {
            //                                         kind: Kind.ARGUMENT,
            //                                         name: {
            //                                             kind: Kind.NAME,
            //                                             loc: { start: 9, end: 11 },
            //                                             value: 'id',
            //                                         },
            //                                         value: {
            //                                             kind: Kind.INT,
            //                                             loc: { start: 13, end: 14 },
            //                                             value: '4',
            //                                         },
            //                                         loc: { start: 9, end: 14 },
            //                                     },
            //                                     ],
            //                                     directives: [],
            //                                     selectionSet: {
            //                                         kind: Kind.SELECTION_SET,
            //                                         loc: { start: 16, end: 38 },
            //                                         selections: [
            //                                         {
            //                                             kind: Kind.FIELD,
            //                                             loc: { start: 22, end: 24 },
            //                                             alias: undefined,
            //                                             name: {
            //                                                 kind: Kind.NAME,
            //                                                 loc: { start: 22, end: 24 },
            //                                                 value: 'id',
            //                                             },
            //                                             arguments: [],
            //                                             directives: [],
            //                                             selectionSet: undefined,
            //                                         },
            //                                         {
            //                                             kind: Kind.FIELD,
            //                                             loc: { start: 30, end: 34 },
            //                                             alias: undefined,
            //                                             name: {
            //                                                 kind: Kind.NAME,
            //                                                 loc: { start: 30, end: 34 },
            //                                                 value: 'name',
            //                                             },
            //                                             arguments: [],
            //                                             directives: [],
            //                                             selectionSet: undefined,
            //                                         },
            //                                         ],
            //                                     },
            //                                 },
            //                                 ],
            //                             },
            //                         },
            //                         ],
            //                     } );
            //                 } );

            //                 it( 'creates ast from nameless query without variables', function() {
            //                     const result = parse(dedent`
            //                     query {
            //                         node {
            //                             id
            //                         }
            //                     }
            //                     `);

            //                     expect(toJSONDeep(result)).to.deep.equal({
            //                         kind: Kind.DOCUMENT,
            //                         loc: { start: 0, end: 30 },
            //                         definitions: [
            //                         {
            //                             kind: Kind.OPERATION_DEFINITION,
            //                             loc: { start: 0, end: 29 },
            //                             operation: 'query',
            //                             name: undefined,
            //                             variableDefinitions: [],
            //                             directives: [],
            //                             selectionSet: {
            //                                 kind: Kind.SELECTION_SET,
            //                                 loc: { start: 6, end: 29 },
            //                                 selections: [
            //                                 {
            //                                     kind: Kind.FIELD,
            //                                     loc: { start: 10, end: 27 },
            //                                     alias: undefined,
            //                                     name: {
            //                                         kind: Kind.NAME,
            //                                         loc: { start: 10, end: 14 },
            //                                         value: 'node',
            //                                     },
            //                                     arguments: [],
            //                                     directives: [],
            //                                     selectionSet: {
            //                                         kind: Kind.SELECTION_SET,
            //                                         loc: { start: 15, end: 27 },
            //                                         selections: [
            //                                         {
            //                                             kind: Kind.FIELD,
            //                                             loc: { start: 21, end: 23 },
            //                                             alias: undefined,
            //                                             name: {
            //                                                 kind: Kind.NAME,
            //                                                 loc: { start: 21, end: 23 },
            //                                                 value: 'id',
            //                                             },
            //                                             arguments: [],
            //                                             directives: [],
            //                                             selectionSet: undefined,
            //                                         },
            //                                         ],
            //                                     },
            //                                 },
            //                                 ],
            //                             },
            //                         },
            //                         ],
            //                     } );
            //                 } );

            //                 it( 'allows parsing without source location information', function() {
            //                     const result = parse('{ id }', { noLocation: true } );
            //                     expect(result.loc).to.equal(undefined);
            //                 } );

            //                 it( 'Experimental: allows parsing fragment defined variables', function() {
            //                     const document = 'fragment a($v: Boolean = false) on t { f(v: $v) }';

            //                     expect(() =>
            //                     parse(document, { experimentalFragmentVariables: true }),
            //                     ).to.not.throw();
            //                     expect(() => parse(document)).to.throw('Syntax Error');
            //                 } );

            //                 it( 'contains location information that only stringifys start/end', function() {
            //                     const result = parse('{ id }');

            //                     expect(JSON.stringify(result.loc)).to.equal('{"start":0,"end":6}');
            //                     expect(inspect(result.loc)).to.equal('{ start: 0, end: 6 }');
            //                 } );

            //                 it( 'contains references to source', function() {
            //                     const source = new Source('{ id }');
            //                     const result = parse(source);

            //                     expect(result.loc.source).to.equal(source);
            //                 } );

            //                 it( 'contains references to start and end tokens', function() {
            //                     const result = parse('{ id }');

            //                     expect(result.loc.startToken.kind).to.equal('<SOF>');
            //                         expect(result.loc.endToken.kind).to.equal('<EOF>');
            //                         } );

            //                         describe('parseValue', function() {
            //                             it( 'parses null value', function() {
            //                                 const result = parseValue('null');
            //                                 expect(toJSONDeep(result)).to.deep.equal({
            //                                     kind: Kind.NULL,
            //                                     loc: { start: 0, end: 4 },
            //                                 } );
            //                             } );

            //                             it( 'parses list values', function() {
            //                                 const result = parseValue('[123 "abc"]');
            //                                 expect(toJSONDeep(result)).to.deep.equal({
            //                                     kind: Kind.LIST,
            //                                     loc: { start: 0, end: 11 },
            //                                     values: [
            //                                     {
            //                                         kind: Kind.INT,
            //                                         loc: { start: 1, end: 4 },
            //                                         value: '123',
            //                                     },
            //                                     {
            //                                         kind: Kind.STRING,
            //                                         loc: { start: 5, end: 10 },
            //                                         value: 'abc',
            //                                         block: false,
            //                                     },
            //                                     ],
            //                                 } );
            //                             } );

            //                             it( 'parses block strings', function() {
            //                                 const result = parseValue('["""long""" "short"]');
            //                                 expect(toJSONDeep(result)).to.deep.equal({
            //                                     kind: Kind.LIST,
            //                                     loc: { start: 0, end: 20 },
            //                                     values: [
            //                                     {
            //                                         kind: Kind.STRING,
            //                                         loc: { start: 1, end: 11 },
            //                                         value: 'long',
            //                                         block: true,
            //                                     },
            //                                     {
            //                                         kind: Kind.STRING,
            //                                         loc: { start: 12, end: 19 },
            //                                         value: 'short',
            //                                         block: false,
            //                                     },
            //                                     ],
            //                                 } );
            //                             } );
            //                         } );

            //                         describe('parseType', function() {
            //                             it( 'parses well known types', function() {
            //                                 const result = parseType('String');
            //                                 expect(toJSONDeep(result)).to.deep.equal({
            //                                     kind: Kind.NAMED_TYPE,
            //                                     loc: { start: 0, end: 6 },
            //                                     name: {
            //                                         kind: Kind.NAME,
            //                                         loc: { start: 0, end: 6 },
            //                                         value: 'String',
            //                                     },
            //                                 } );
            //                             } );

            //                             it( 'parses custom types', function() {
            //                                 const result = parseType('MyType');
            //                                 expect(toJSONDeep(result)).to.deep.equal({
            //                                     kind: Kind.NAMED_TYPE,
            //                                     loc: { start: 0, end: 6 },
            //                                     name: {
            //                                         kind: Kind.NAME,
            //                                         loc: { start: 0, end: 6 },
            //                                         value: 'MyType',
            //                                     },
            //                                 } );
            //                             } );

            //                             it( 'parses list types', function() {
            //                                 const result = parseType('[MyType]');
            //                                 expect(toJSONDeep(result)).to.deep.equal({
            //                                     kind: Kind.LIST_TYPE,
            //                                     loc: { start: 0, end: 8 },
            //                                     type: {
            //                                         kind: Kind.NAMED_TYPE,
            //                                         loc: { start: 1, end: 7 },
            //                                         name: {
            //                                             kind: Kind.NAME,
            //                                             loc: { start: 1, end: 7 },
            //                                             value: 'MyType',
            //                                         },
            //                                     },
            //                                 } );
            //                             } );

            //                             it( 'parses non-null types', function() {
            //                                 const result = parseType('MyType!');
            //                                 expect(toJSONDeep(result)).to.deep.equal({
            //                                     kind: Kind.NON_NULL_TYPE,
            //                                     loc: { start: 0, end: 7 },
            //                                     type: {
            //                                         kind: Kind.NAMED_TYPE,
            //                                         loc: { start: 0, end: 6 },
            //                                         name: {
            //                                             kind: Kind.NAME,
            //                                             loc: { start: 0, end: 6 },
            //                                             value: 'MyType',
            //                                         },
            //                                     },
            //                                 } );
            //                             } );

            //                             it( 'parses nested types', function() {
            //                                 const result = parseType('[MyType!]');
            //                                 expect(toJSONDeep(result)).to.deep.equal({
            //                                     kind: Kind.LIST_TYPE,
            //                                     loc: { start: 0, end: 9 },
            //                                     type: {
            //                                         kind: Kind.NON_NULL_TYPE,
            //                                         loc: { start: 1, end: 8 },
            //                                         type: {
            //                                             kind: Kind.NAMED_TYPE,
            //                                             loc: { start: 1, end: 7 },
            //                                             name: {
            //                                                 kind: Kind.NAME,
            //                                                 loc: { start: 1, end: 7 },
            //                                                 value: 'MyType',
            //                                             },
            //                                         },
            //                                     },
            //                                 } );
            //                             } );
            //                         } );
            //                     } );

            //                 }
            //             }
