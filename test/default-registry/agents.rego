package main
agents := {
  "base": {"container": "base", "image": "docker.io/amambadev/jenkins-agent-base:latest-podman"},
  "go": {"container": "go", "image": "docker.io/amambadev/jenkins-agent-go:latest-1.22.6-ubuntu-podman"},
  "go-1.17.13": {"container": "go", "image": "docker.io/amambadev/jenkins-agent-go:latest-1.17.13-ubuntu-podman"},
  "go-1.18.10": {"container": "go", "image": "docker.io/amambadev/jenkins-agent-go:latest-1.18.10-ubuntu-podman"},
  "go-1.20.14": {"container": "go", "image": "docker.io/amambadev/jenkins-agent-go:latest-1.20.14-ubuntu-podman"},
  "python": {"container": "python", "image": "docker.io/amambadev/jenkins-agent-python:latest-3.8.19-podman"},
  "python-2.7.9": {"container": "python", "image": "docker.io/amambadev/jenkins-agent-python:latest-2.7.9-ubuntu-podman"},
  "python-3.10.9": {"container": "python", "image": "docker.io/amambadev/jenkins-agent-python:latest-3.10.9-ubuntu-podman"},
  "python-3.11.9": {"container": "python", "image": "docker.io/amambadev/jenkins-agent-python:latest-3.11.9-ubuntu-podman"},
  "maven": {"container": "maven", "image": "docker.io/amambadev/jenkins-agent-maven:latest-jdk8-ubuntu-podman"},
  "maven-jdk11": {"container": "maven", "image": "docker.io/amambadev/jenkins-agent-maven:latest-jdk11-ubuntu-podman"},
  "maven-jdk17": {"container": "maven", "image": "docker.io/amambadev/jenkins-agent-maven:latest-jdk17-ubuntu-podman"},
  "maven-jdk21": {"container": "maven", "image": "docker.io/amambadev/jenkins-agent-maven:latest-jdk21-ubuntu-podman"},
  "nodejs": {"container": "nodejs", "image": "docker.io/amambadev/jenkins-agent-nodejs:latest-16.20.2-podman"},
  "nodejs-18.20.4": {"container": "nodejs", "image": "docker.io/amambadev/jenkins-agent-nodejs:latest-18.20.4-ubuntu-podman"},
  "nodejs-20.17.0": {"container": "nodejs", "image": "docker.io/amambadev/jenkins-agent-nodejs:latest-20.17.0-ubuntu-podman"}
}
