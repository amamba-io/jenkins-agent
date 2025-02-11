package main

empty(value) {
	count(value) == 0
}

no_violations {
	empty(deny)
}

test_casc_with_valid_image {
	input := {
		"apiVersion": "v1",
		"kind": "ConfigMap",
		"metadata": {"name": "jenkins-casc-config"},
		"data": {"jenkins.yaml": "jenkins:\n  clouds:\n    - kubernetes:\n        templates:\n          - name: \"base\"\n            namespace: \"jenkins\"\n            containers:\n            - name: \"base\"\n              image: \"ghcr.io/amamba-io/jenkins-agent-base:latest\"\n            - name: \"jnlp\"\n              image: \"ghcr.io/amamba-io/inbound-agent:4.10-2\"\n          - name: \"nodejs\"\n            namespace: \"jenkins\"\n            containers:\n            - name: \"nodejs\"\n              image: \"ghcr.io/amamba-io/jenkins-agent-nodejs:latest\"\n            - name: \"jnlp\"\n              image: \"ghcr.io/amamba-io/inbound-agent:4.10-2\"\n"},
	}
	no_violations with input as input
}

test_casc_with_invalid_base {
	input := {
		"apiVersion": "v1",
		"kind": "ConfigMap",
		"metadata": {"name": "jenkins-casc-config"},
		"data": {"jenkins.yaml": "jenkins:\n  clouds:\n    - kubernetes:\n        templates:\n          - name: \"base\"\n            namespace: \"jenkins\"\n            containers:\n            - name: \"base\"\n              image: \"base:latest\"\n            - name: \"jnlp\"\n              image: \"ghcr.io/amamba-io/inbound-agent:4.10-2\"\n          - name: \"nodejs\"\n            namespace: \"jenkins\"\n            containers:\n            - name: \"nodejs\"\n              image: \"ghcr.io/amamba-io/jenkins-agent-nodejs:latest\"\n            - name: \"jnlp\"\n              image: \"ghcr.io/amamba-io/inbound-agent:4.10-2\"\n"},
	}
	deny["'base' should not use image: 'base:latest'"] with input as input
}

test_casc_with_invalid_jnlp {
	input := {
		"apiVersion": "v1",
		"kind": "ConfigMap",
		"metadata": {"name": "jenkins-casc-config"},
		"data": {"jenkins.yaml": "jenkins:\n  clouds:\n    - kubernetes:\n        templates:\n          - name: \"base\"\n            namespace: \"jenkins\"\n            containers:\n            - name: \"base\"\n              image: \"ghcr.io/amamba-io/jenkins-agent-base:latest\"\n            - name: \"jnlp\"\n              image: \"ghcr.io/amamba-io/inbound-agent:4.10-2\"\n          - name: \"nodejs\"\n            namespace: \"jenkins\"\n            containers:\n            - name: \"nodejs\"\n              image: \"ghcr.io/amamba-io/jenkins-agent-nodejs:latest\"\n            - name: \"jnlp\"\n              image: \"ghcr.io/amamba-io/inbound-agent:4.10-2\"\n"},
	}
	deny["'jnlp' should not use image: 'inbound-agent:4.10-2'"] with input as input
}

test_default_deployments_image {
	input := {
		"kind": "Deployment",
		"metadata": {"name": "jenkins"},
		"spec": {"template": {"spec": {
			"initContainers": [
				{
					"name": "copy-default-config",
					"image": "ghcr.io/amamba-io/jenkins:latest-2.413",
				},
				{
					"name": "opentelemetry-auto-instrumentation",
					"image": "ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-java:1.17.0",
				},
			],
			"containers": [
				{
					"name": "jenkins",
					"image": "ghcr.io/amamba-io/jenkins:latest-2.413",
				},
				{
					"name": "event-proxy",
					"image": "release.daocloud.io/amamba/amamba-event-proxy:v0.18.0-alpha.0",
				},
			],
		}}},
	}
	no_violations with input as input
}

test_cotainers_missing {
	input := {
		"kind": "Deployment",
		"metadata": {"name": "jenkins"},
		"spec": {"template": {"spec": {
			"initContainers": [{
				"name": "copy-default-config",
				"image": "ghcr.io/amamba-io/jenkins:latest-2.413",
			}],
			"containers": [{
				"name": "jenkins",
				"image": "ghcr.io/amamba-io/jenkins:latest-2.413",
			}],
		}}},
	}
	deny["'opentelemetry-auto-instrumentation' is not enabled"] with input as input
	deny["'event-proxy' is not enabled"] with input as input
}
