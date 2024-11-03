(
    (attribute
        name: (attribute_name) @name
        value: (quoted_attribute_value
            (attribute_value) @injection.content
        )
    )
    (#match? @name "data-[a-z]+")
    (#set! injection.language "javascript")
)
