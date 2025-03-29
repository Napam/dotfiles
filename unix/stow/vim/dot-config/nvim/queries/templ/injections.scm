; (
;     (attribute
;         name: (attribute_name) @name
;         value: (quoted_attribute_value
;             (attribute_value) @injection.content
;         )
;     )
;     (#match? @name "data-[a-z]+")
;     (#set! injection.language "javascript")
; )

(
    (attribute
        name: (attribute_name) @name
        value: (quoted_attribute_value
            (attribute_value) @injection.content
        )
    )
    (#match? @name "data-[a-z]+|onchange|onclick|oninput|onkeydown|onkeyup|onmousedown|onmouseup|onmouseover|onmouseout|onmouseenter|onmouseleave|onsubmit|onfocus|onblur")
    (#set! injection.language "javascript")
)

(
    (script_element
        (script_element_text) @injection.content
    )
    (#set! injection.language "javascript")
)
