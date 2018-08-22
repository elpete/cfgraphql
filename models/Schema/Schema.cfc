component accessors="true" {

    property name="query";
    property name="mutation";

    public Schema function init( required ObjectType query, required ObjectType mutation ) {
        setQuery( query );
        setMutation( mutation );
        return this;
    }

}
