; extends

; SQL: sqlite3, psycopg, sqlalchemy.text, pandas.read_sql*, polars.read_database, etc.
; Matches both bare and method-attribute calls.
; WARN: name-only match; custom non-SQL `execute()` will false-positive.
((call
  function: [
    (attribute
      attribute: (identifier) @_id)
    (identifier) @_id
  ]
  arguments: (argument_list
    .
    (string
      (string_content) @injection.content)))
  (#any-of? @_id
    "execute" "executemany" "executescript" "read_sql" "read_sql_query" "read_sql_table"
    "read_database" "text" "from_statement")
  (#set! injection.language "sql"))

; query = "SELECT ..." / sql_query = "..." / SQL = "..."
((assignment
  left: (identifier) @_id
  right: (string
    (string_content) @injection.content))
  (#match? @_id "^(query|sql_query|sql|SQL|QUERY)$")
  (#set! injection.language "sql"))

; markdown(...) → markdown
((call
  function: [
    (attribute
      attribute: (identifier) @_id)
    (identifier) @_id
  ]
  arguments: (argument_list
    .
    (string
      (string_content) @injection.content)))
  (#eq? @_id "markdown")
  (#set! injection.language "markdown"))

; re.compile / re.match / re.search / re.findall / re.sub etc. → regex
((call
  function: (attribute
    object: (identifier) @_pkg
    attribute: (identifier) @_fn)
  arguments: (argument_list
    .
    (string
      (string_content) @injection.content)))
  (#eq? @_pkg "re")
  (#any-of? @_fn "compile" "match" "search" "findall" "finditer" "fullmatch" "split" "sub" "subn")
  (#set! injection.language "regex"))

; subprocess.run/Popen/check_output(["sh", "-c", "..."]) is too dynamic to
; inject safely. Skipping shell injection — high false-positive rate.
