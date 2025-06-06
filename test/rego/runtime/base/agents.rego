package main
agents := {
  "base": {"container": "base", "image": "ghcr.io/amamba-io/jenkins-agent-base:latest-ubuntu"},
  "go": {"container": "go", "image": "ghcr.io/amamba-io/jenkins-agent-go:latest-1.22.6-ubuntu"},
  "python": {"container": "python", "image": "ghcr.io/amamba-io/jenkins-agent-python:latest-3.8.19-ubuntu"},
  "maven": {"container": "maven", "image": "ghcr.io/amamba-io/jenkins-agent-maven:latest-jdk8-ubuntu"},
  "nodejs": {"container": "nodejs", "image": "ghcr.io/amamba-io/jenkins-agent-nodejs:latest-16.20.2-ubuntu"}
}