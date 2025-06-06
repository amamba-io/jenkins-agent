package main
agents := {
  "base": {"container": "base", "image": "ghcr.io/amamba-io/jenkins-agent-base:latest-ubuntu"},
  "go": {"container": "go", "image": "ghcr.io/amamba-io/jenkins-agent-go:latest-1.22.6-ubuntu"},
  "go-1.17.13": {"container": "go", "image": "ghcr.io/amamba-io/jenkins-agent-go:latest-1.17.13-ubuntu"},
  "go-1.18.10": {"container": "go", "image": "ghcr.io/amamba-io/jenkins-agent-go:latest-1.18.10-ubuntu"},
  "go-1.20.14": {"container": "go", "image": "ghcr.io/amamba-io/jenkins-agent-go:latest-1.20.14-ubuntu"},
  "python": {"container": "python", "image": "ghcr.io/amamba-io/jenkins-agent-python:latest-3.8.19-ubuntu"},
  "python-2.7.9": {"container": "python", "image": "ghcr.io/amamba-io/jenkins-agent-python:latest-2.7.9-ubuntu"},
  "python-3.10.9": {"container": "python", "image": "ghcr.io/amamba-io/jenkins-agent-python:latest-3.10.9-ubuntu"},
  "python-3.11.9": {"container": "python", "image": "ghcr.io/amamba-io/jenkins-agent-python:latest-3.11.9-ubuntu"},
  "maven": {"container": "maven", "image": "ghcr.io/amamba-io/jenkins-agent-maven:latest-jdk8-ubuntu"},
  "maven-jdk11": {"container": "maven", "image": "ghcr.io/amamba-io/jenkins-agent-maven:latest-jdk11-ubuntu"},
  "maven-jdk17": {"container": "maven", "image": "ghcr.io/amamba-io/jenkins-agent-maven:latest-jdk17-ubuntu"},
  "maven-jdk21": {"container": "maven", "image": "ghcr.io/amamba-io/jenkins-agent-maven:latest-jdk21-ubuntu"},
  "nodejs": {"container": "nodejs", "image": "ghcr.io/amamba-io/jenkins-agent-nodejs:latest-16.20.2-ubuntu"},
  "nodejs-18.20.4": {"container": "nodejs", "image": "ghcr.io/amamba-io/jenkins-agent-nodejs:latest-18.20.4-ubuntu"},
  "nodejs-20.17.0": {"container": "nodejs", "image": "ghcr.io/amamba-io/jenkins-agent-nodejs:latest-20.17.0-ubuntu"}
}