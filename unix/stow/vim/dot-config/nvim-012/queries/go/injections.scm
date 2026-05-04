; extends

; SQL: db/sql, sqlx, pgx, gorm, bun, sqlc, ent. Matches both raw (`...`) and
; interpreted ("...") string literals as the first arg.
; WARN: pattern matches by method *name* only; a custom non-SQL method named
; e.g. `Query` will get a false-positive injection.
((call_expression
  function: (selector_expression
    field: (field_identifier) @_method)
  arguments: (argument_list
    .
    [
      (raw_string_literal
        (raw_string_literal_content) @injection.content)
      (interpreted_string_literal
        (interpreted_string_literal_content) @injection.content)
    ]))
  (#any-of? @_method
    "Exec" "ExecContext" "Query" "QueryContext" "QueryRow" "QueryRowContext" "Prepare"
    "PrepareContext" "Get" "Select" "NamedExec" "NamedQuery" "MustExec" "Raw" "QueryRowx" "Queryx"
    "GetContext" "SelectContext")
  (#set! injection.language "sql"))

; regexp.MustCompile / regexp.Compile → regex
((call_expression
  function: (selector_expression
    operand: (identifier) @_pkg
    field: (field_identifier) @_fn)
  arguments: (argument_list
    .
    [
      (raw_string_literal
        (raw_string_literal_content) @injection.content)
      (interpreted_string_literal
        (interpreted_string_literal_content) @injection.content)
    ]))
  (#eq? @_pkg "regexp")
  (#any-of? @_fn "MustCompile" "Compile" "MatchString" "Match")
  (#set! injection.language "regex"))
