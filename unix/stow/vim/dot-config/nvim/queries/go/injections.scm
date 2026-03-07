; extends

((call_expression
  function: (selector_expression
    field: (field_identifier) @_method)
  arguments: (argument_list
    .
    (raw_string_literal
      (raw_string_literal_content) @injection.content)))
  (#any-of? @_method "Exec" "ExecContext" "Query" "QueryContext" "QueryRow" "QueryRowContext" "Prepare" "PrepareContext")
  (#set! injection.language "sql"))
