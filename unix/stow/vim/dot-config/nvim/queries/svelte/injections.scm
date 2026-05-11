; extends

; Plain <script> (no lang=) → typescript. Stock query only handles lang="ts"/"js".
; TS is a superset of JS, so plain JS still highlights.
; WARN: \b anchors lang= so data-lang= etc. don't false-negative.
((script_element
  (start_tag) @_tag
  (raw_text) @injection.content)
  (#not-match? @_tag "\\blang=")
  (#set! injection.language "typescript"))

; Plain <style> (no lang=) → CSS.
((style_element
  (start_tag) @_tag
  (raw_text) @injection.content)
  (#not-match? @_tag "\\blang=")
  (#set! injection.language "css"))
