import sys
import yaml
from jinja2 import Template
from typing import List


full_rego_jinja_template = """package main
agents := {
{% for item in items %}  "{{ item.name }}": {"container": "{{ item.container }}", "image": "ghcr.io/amamba-io/jenkins-agent-{{ item.container }}:{{ item.version }}-{{ item.os }}{{ item.podman_suffix }}"}{% if not loop.last %},\n{% endif %}{% endfor %}
}
"""

#Render me with data:
"""
items = [
    {   
        "name": "base",
        "container": "base",
        "version": "latest",
        "os": os,
        "podman_suffix": "-podman"
    },
    {   
        "name": "go",
        "container": "go",
        "version": "latest-1.22.6",
        "os": os,
        "podman_suffix": "-podman"
    },
]
"""


class Builder:
    def __init__(self, name, container, version, os="ubuntu", podman_suffix=""):
        self.name = name
        self.container = container
        self.version = version
        self.os = os
        self.podman_suffix = podman_suffix

    def __repr__(self):
        return f"BuilderItem(name={self.name}, container={self.container}, version={self.version}, os={self.os}, podman_suffix={self.podman_suffix})"

    @classmethod
    def from_yaml(cls, name: str, data: dict, os: str, podman: bool) -> List['Builder']:
        items = []
        podman_suffix = "-podman" if podman else ""
        tag = data.get("ImageTag", "latest")
        items.append(cls(    
            name=name,
            container=name,
            version=tag,
            os=os,
            podman_suffix=podman_suffix
        ))

        versions = data.get("Versions", [])
        for version in versions:
            version_short = version.split('-')[-1]
            items.append(cls(
                name=f"{name}-{version_short}",
                container=name,
                version=version,
                os=os,
                podman_suffix=podman_suffix
            ))
        return items

# YAML has following structure:
"""Agent:
  Builder:
    Base:
      Image: amamba-io/jenkins-agent-base
      ImageTag: latest
    NodeJs:
      Image: amamba-io/jenkins-agent-nodejs
      ImageTag: latest-16.20.2
      # Versions for auto generator Jenkins CASC Config and relock_k8s images.
      # must build image first.
      Versions:
        - latest-18.20.4
        - latest-20.17.0
    Maven:
      Image: amamba-io/jenkins-agent-maven
      ImageTag: latest-jdk8
      Versions:
        - latest-jdk11
        - latest-jdk17
        - latest-jdk21
    Golang:
      Image: amamba-io/jenkins-agent-go
      ImageTag: latest-1.22.6
      Versions:
        - latest-1.17.13
        - latest-1.18.10
        - latest-1.20.14
    Python:
      Image: amamba-io/jenkins-agent-python
      ImageTag: latest-3.8.19
      Versions:
        - latest-2.7.9
        - latest-3.10.9
        - latest-3.11.9
    ContainerRuntime: podman # Available values: docker, podman
"""
def parse_values_yaml(yaml_path, os, use_podman):
    """Parse the values.yaml content and generate items list for rendering."""
    with open(yaml_path, 'r') as file:
        data = yaml.safe_load(file)

    agents_data = data.get('Agent', {}).get('Builder', {})
    items = []
    base_info = agents_data.get('Base', {})
    items += Builder.from_yaml("base", base_info, os, use_podman)

    golang_info = agents_data.get('Golang', {})
    items += Builder.from_yaml("go", golang_info, os, use_podman)
    
    python_info = agents_data.get('Python', {})
    items += Builder.from_yaml("python", python_info, os, use_podman)
    
    maven_info = agents_data.get('Maven', {})
    items += Builder.from_yaml("maven", maven_info, os, use_podman)
    
    nodejs_info = agents_data.get('NodeJs', {})
    items += Builder.from_yaml("nodejs", nodejs_info, os, use_podman)
    return items

def main(path_to_yaml, target_path, os, use_podman):
    # Parse values.yaml and generate items list
    items = parse_values_yaml(path_to_yaml, os, use_podman)
    
    # Render the template with the generated items
    template = Template(full_rego_jinja_template)
    rendered = template.render(items=items)
    with open(target_path, 'w') as f:
        f.write(rendered)

if __name__ == "__main__":
    path_to_yaml = sys.argv[1] 
    target_path = sys.argv[2] 
    use_podman = sys.argv[3] if len(sys.argv) > 3 else 'true'
    use_podman = use_podman.lower() == 'true'
    os = sys.argv[4] if len(sys.argv) > 4 else 'ubuntu'
    main(path_to_yaml, target_path, os, use_podman)
