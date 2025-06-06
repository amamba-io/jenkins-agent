package main

import future.keywords.if

deny contains msg if {
    input.kind == "ConfigMap"
    input.metadata.name == "insecure-registries"

    registries_conf := input.data["registries.conf"]
    not has_correct_content(registries_conf)
    msg := sprintf("insecure registry configuration is not rendered: '%v'", [registries_conf])
}

has_correct_content(content) if {
    content == `[[registry]]
location = "10.6.182.195:5000"
insecure = true
`
}