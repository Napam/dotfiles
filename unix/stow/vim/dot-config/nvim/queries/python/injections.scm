(call
  function: (attribute attribute: (identifier) @id (#match? @id "executemany|execute|read_sql|text"))
  arguments: (argument_list
    (string (string_content) @injection.content (#set! injection.language "sql"))))

(call
  function: (attribute attribute: (identifier) @id (#match? @id "markdown"))
  arguments: (argument_list
    (string (string_content) @injection.content (#set! injection.language "markdown"))))
