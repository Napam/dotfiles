(call
  function: (attribute attribute: (identifier) @id (#match? @id "executemany|execute|read_sql"))
  arguments: (argument_list
    (string (string_content) @injection.content (#set! injection.language "sql"))))