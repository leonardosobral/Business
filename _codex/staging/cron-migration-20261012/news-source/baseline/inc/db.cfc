component output="false" {

  public any function q(string sql, struct params = {}, struct opts = {}){
    if (!structKeyExists(opts, "datasource") && structKeyExists(application, "datasource")){
      opts.datasource = application.datasource;
    }
    return QueryExecute(arguments.sql, arguments.params, arguments.opts);
  }

  public boolean function columnExists(required string schemaName, required string tableName, required string columnName, struct opts = {}){
    var params = {
      table_schema = { value = arguments.schemaName, cfsqltype = "cf_sql_varchar" },
      table_name = { value = arguments.tableName, cfsqltype = "cf_sql_varchar" },
      column_name = { value = arguments.columnName, cfsqltype = "cf_sql_varchar" }
    };
    var lookup = "";

    lookup = q("
      SELECT 1
      FROM information_schema.columns
      WHERE table_schema = :table_schema
        AND table_name = :table_name
        AND column_name = :column_name
      LIMIT 1
    ", params, arguments.opts);

    return lookup.recordCount GT 0;
  }

  public string function findTableSchema(required string tableName, string preferredSchemas = "", struct opts = {}){
    var schemaList = [];
    var schemaValue = "";
    var params = {
      table_name = { value = arguments.tableName, cfsqltype = "cf_sql_varchar" }
    };
    var sql = "
      SELECT table_schema
      FROM information_schema.tables
      WHERE table_name = :table_name
        AND table_schema NOT IN ('information_schema', 'pg_catalog')
    ";
    var lookup = "";

    if (len(trim(arguments.preferredSchemas))) {
      schemaList = listToArray(arguments.preferredSchemas);
      sql &= " AND table_schema IN (";

      for (var i = 1; i <= arrayLen(schemaList); i = i + 1) {
        if (i GT 1) {
          sql &= ", ";
        }

        schemaValue = trim(schemaList[i]);
        params["schema_" & i] = { value = schemaValue, cfsqltype = "cf_sql_varchar" };
        sql &= ":schema_" & i;
      }

      sql &= ")";
    }

    sql &= "
      ORDER BY CASE table_schema
        WHEN 'news' THEN 0
        WHEN 'public' THEN 1
        ELSE 2
      END, table_schema ASC
      LIMIT 1
    ";

    lookup = q(sql, params, arguments.opts);

    if (!lookup.recordCount) {
      return "";
    }

    return trim(lookup.table_schema[1] & "");
  }

}
