package main

deny contains msg if {
	input.kind == "Deployment"
	image := input.spec.template.spec.containers[_].image
	not startswith(image, "my-company.com/")

	msg := sprintf("image '%v' doesn't come from my-company.com repository", [image])
}

deny contains msg if {
	input.kind == "Deployment"
	image := input.spec.template.spec.initContainers[_].image
	not startswith(image, "my-company.com/")

	msg := sprintf("image '%v' doesn't come from my-company.com repository", [image])
}

deny contains msg if {
	input.kind == "ConfigMap"
	input.metadata.name == "jenkins-casc-config"

	content := input.data["jenkins.yaml"]
	obj := yaml.unmarshal(content)
	image := obj.jenkins.clouds[_].kubernetes.templates[_].containers[_].image
	not startswith(image, "my-company.com/")

	msg := sprintf("image '%v' doesn't come from my-company.com repository", [image])
}
