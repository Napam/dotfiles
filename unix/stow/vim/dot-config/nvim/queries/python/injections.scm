(call
  function: [
    (attribute attribute: (identifier) @id)
    (identifier) @id
  ] (#match? @id "executemany|execute|read_sql|read_database|text")
  arguments: (argument_list
    (string (string_content) @injection.content (#set! injection.language "sql"))))

(assignment
  left: (identifier) @id (#match? @id "query|sql_query")
  right: (string
    (string_content) @injection.content (#set! injection.language "sql")))

(call
  function: [
    (attribute attribute: (identifier) @id)
    (identifier) @id
  ] (#match? @id "markdown")
  arguments: (argument_list
    (string (string_content) @injection.content (#set! injection.language "markdown"))))
