; extends

; HTML event handlers + htmx attrs (incl. hx-on:click etc.) + alpine.js (x-on, @click, :class)
; → JavaScript.
((attribute
  name: (attribute_name) @_name
  value: (quoted_attribute_value
    (attribute_value) @injection.content))
  ; WARN: tree-sitter #match? wraps patterns in \v (very magic). Bare @ is the
  ; \@ operator prefix in very-magic mode → E866. Use [@] for a literal.
  (#match? @_name "^(on[a-z]+|hx-on:[a-z:-]+|x-[a-z:.-]+|[@][a-z:.-]+|:[a-z:.-]+|data-[a-z0-9-_:.]+)$")
  (#set! injection.language "javascript"))

; <script>...</script> → JavaScript.
((script_element
  (script_element_text) @injection.content)
  (#set! injection.language "javascript"))

; <style>...</style> → CSS.
((style_element
  (style_element_text) @injection.content)
  (#set! injection.language "css"))

; style="..." attribute → CSS.
((attribute
  name: (attribute_name) @_name
  value: (quoted_attribute_value
    (attribute_value) @injection.content))
  (#eq? @_name "style")
  (#set! injection.language "css"))
