; extends

; k8s containers: command/args (sequence form). Also Compose, Ansible.
((block_mapping_pair
  key: (flow_node
    (plain_scalar
      (string_scalar) @_key))
  value: (block_node
    (block_sequence
      (block_sequence_item
        (block_node
          (block_scalar) @injection.content)))))
  (#any-of? @_key "args" "command" "cmds" "entrypoint" "cmd" "script")
  (#set! injection.language "bash"))

; Same keys, scalar form. GitHub Actions `run:`, GitLab CI script item,
; k8s lifecycle hook `command:`, Compose `entrypoint:`/`command:` string form.
((block_mapping_pair
  key: (flow_node
    (plain_scalar
      (string_scalar) @_key))
  value: (block_node
    (block_scalar) @injection.content))
  (#any-of? @_key "args" "command" "cmds" "entrypoint" "cmd" "script" "run" "shell")
  (#set! injection.language "bash"))

; GitHub Actions `run:` with a flow scalar (single-line).
; WARN: flow-scalar form is whitespace-stripped; multi-line scripts should use `|`.
((block_mapping_pair
  key: (flow_node
    (plain_scalar
      (string_scalar) @_key))
  value: (flow_node
    [
      (double_quote_scalar)
      (single_quote_scalar)
      (plain_scalar)
    ] @injection.content))
  (#any-of? @_key "run")
  (#set! injection.language "bash"))

; Prometheus expr / Grafana query.
((block_mapping_pair
  key: (flow_node
    (plain_scalar
      (string_scalar) @_key))
  value: (block_node
    (block_scalar) @injection.content))
  (#eq? @_key "expr")
  (#set! injection.language "promql"))
