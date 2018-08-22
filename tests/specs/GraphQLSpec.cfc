component extends="testbox.system.BaseSpec" {

    function run() {
        describe( "GraphQL", function() {
            it( "works", function() {
                // var rootResolver = {
                //     "query" = {
                //         "getHero" = function( obj, args, context ) {
                //             return {
                //                 "getName" = function( obj, args, context ) {
                //                     return  "R2-D2";
                //                 }
                //             };
                //         }
                //     }
                // };

                var schema = new models.Schema.Schema(
                    query = new models.Schema.ObjectType(),
                    mutation = new models.Schema.ObjectType()
                );

                // var schema = "
                //     type Query {
                //         hero: Hero
                //     }

                //     type Hero {
                //         name: String
                //     }
                // ";
                var graphql = new models.GraphQLClient( schema );
                var rawQuery = "
                    query HeroNameQuery {
                        hero {
                           name
                        }
                    }
                ";
                var result = graphql.execute( rawQuery );
                debug( result );
                expect( result ).toBeStruct();
                expect( result ).toBe( {
                    data = {
                        hero = {
                            name = "R2-D2"
                        }
                    }
                } );
            } );

            it( "works again", function() {
                var humans = {
                    "1000" = {
                        getName = function( obj, args, context ) {
                            return "Luke Skywalker";
                        }
                    }
                };
                var rootResolver = {
                    "query" = {
                        "getHuman" = function( obj, args, context ) {
                            return humans[ args.id ];
                        }
                    }
                };
                var schema = "
                    type Query {
                        human(id: String): Character
                    }

                    type Character {
                        name: String
                    }
                ";
                var graphql = new models.GraphQLClient( "", rootResolver );
                var rawQuery = '
                    query FetchLukeQuery {
                        human(id: "1000") {
                            name
                        }
                    }
                ';
                var result = graphql.execute( rawQuery );
                debug( result );
                expect( result ).toBeStruct();
                expect( result ).toBe( {
                    data = {
                        human = {
                            name = "Luke Skywalker"
                        }
                    }
                } );
            } );
        } );
    }

}
