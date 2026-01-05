; Inject shell syntax for command and args blocks in Kubernetes manifests
(block_mapping_pair
  key: (flow_node
    (plain_scalar
      (string_scalar) @_key))
  value: (block_node
    (block_sequence
      (block_sequence_item
        (block_node
          (block_scalar) @injection.content))))
  (#match? @_key "^(args|command)$")
  (#set! injection.language "bash"))

; Also inject shell for script-like content in single string values
(block_mapping_pair
  key: (flow_node
    (plain_scalar
      (string_scalar) @_key))
  value: (block_node
    (block_scalar) @injection.content)
  (#match? @_key "^(script|command|entrypoint)$")
  (#set! injection.language "bash"))


(block_mapping_pair
  key: (flow_node
    (plain_scalar
      (string_scalar) @_key))
  value: (block_node
    (block_scalar) @injection.content)
  (#match? @_key "^(expr)$")
  (#set! injection.language "promql"))
