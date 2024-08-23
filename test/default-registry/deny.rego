package main

import future.keywords.every
import future.keywords.if

deny[msg] {
	input.kind == "Deployment"
	container := input.spec.template.spec.initContainers[_]
	not is_copy_default_config_image(container)
	not is_instrumentation_image(container)

	msg := sprintf("%v should not use image: '%v'", [container.name, container.image])
}

is_copy_default_config_image(container) if {
	container.name == "copy-default-config"
	container.image == "docker.io/amambadev/jenkins:latest-2.413"
}

is_instrumentation_image(container) if {
	container.name == "opentelemetry-auto-instrumentation"
	container.image == "ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-java:1.17.0"
}

deny[msg] {
	input.kind == "Deployment"
	container := input.spec.template.spec.containers[_]
	not is_jenkins_image(container)
	not is_event_proxy_image(container)

	msg := sprintf("%v should not use image: '%v'", [container.name, container.image])
}

is_jenkins_image(container) if {
	container.name == "jenkins"
	container.image == "docker.io/amambadev/jenkins:latest-2.413"
}

is_event_proxy_image(container) if {
	container.name == "event-proxy"
	container.image == "release.daocloud.io/amamba/amamba-event-proxy:v0.18.0-alpha.0"
}

deny[msg] {
	input.kind == "Deployment"
	not has_container(input.spec.template.spec.containers, "event-proxy")

	msg := "'event-proxy' is not enabled"
}

deny[msg] {
	input.kind == "Deployment"
	not has_container(input.spec.template.spec.initContainers, "opentelemetry-auto-instrumentation")

	msg := "'opentelemetry-auto-instrumentation' is not enabled"
}

has_container(containers, name) if {
	some i
	containers[i].name == name
}

deny[msg] {
	input.kind == "ConfigMap"
	input.metadata.name == "jenkins-casc-config"

	data1 := input.data["jenkins.yaml"]
	obj := yaml.unmarshal(data1)
	msg := find_unknown_images(obj.jenkins.clouds[_].kubernetes.templates[_].containers[_])
}

agents := {
	"base": {"container": "base", "image": "docker.io/amambadev/jenkins-agent-base:latest-*"},
	"maven": {"container": "maven", "image": "docker.io/amambadev/jenkins-agent-maven:latest-*"},
	"nodejs": {"container": "nodejs", "image": "docker.io/amambadev/jenkins-agent-nodejs:latest-*"},
	"go": {"container": "go", "image": "docker.io/amambadev/jenkins-agent-go:latest-*"},
	"python": {"container": "python", "image": "docker.io/amambadev/jenkins-agent-python:latest-*"},
}

is_jnlp_image(container) if {
	container.name == "jnlp"
	container.image == "docker.io/jenkins/inbound-agent:4.10-2"
}

is_agent_image(container) if {
	some name
	agents[name].container == container.name
	re_match(agents[name].image, container.image)
}

find_unknown_images(container) := msg if {
	not is_jnlp_image(container)
	not is_agent_image(container)
	msg := sprintf("'%v' should not use image: '%v'", [container.name, container.image])
}
