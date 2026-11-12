"""Build PR images locally; never authenticate or publish images."""
import os
import subprocess
import yaml


def run(*args):
    subprocess.run(args, check=True)


def select(paths):
    # Legacy CentOS sources are retained for manual builds only.
    paths = [p for p in paths if p not in ('jenkins-agent/base/Dockerfile.centos',
                                          'jenkins-agent/base/ansible/playbooks/centos.yaml') and
             not p.startswith('jenkins-agent/base/ansible/playbooks/tasks/centos/')]
    all_agents = any(p.startswith(('jenkins-agent/base/', 'tools/', 'hack/ci/')) or
                     p in ('go.mod', 'go.sum', 'version.yaml', '.github/workflows/pr_checks.yaml',
                           'test/e2e/check_agent_base_tools.sh', 'test/e2e/check_agent_software_tools.sh') or
                     p.startswith('test/fixture/image-check/base-agent/') for p in paths)
    agents = [a for a in ('nodejs', 'python', 'go', 'maven') if all_agents or any(
        p.startswith((f'jenkins-agent/{a}/', f'test/fixture/image-check/{a}-agent/')) for p in paths)]
    jenkins = any(p in ('Dockerfile', 'formula.yaml', 'remove-bundle-plugins.groovy',
                       '.github/workflows/pr_checks.yaml') or p.startswith('hack/ci/') for p in paths)
    return all_agents, agents, jenkins


def main():
    paths = subprocess.check_output(['git', 'diff', '--name-only', '-z',
                                    os.environ['BASE_SHA'] + '...' + os.environ['HEAD_SHA']], text=True).split('\0')
    base, agents, jenkins = select(paths)
    inbound = any(p.startswith('jenkins-agent/inbound/') or p in (
        '.github/workflows/build_jenkins.yaml', 'test/e2e/check_inbound_agent.sh',
        '.github/workflows/pr_checks.yaml') or p.startswith('hack/ci/') for p in paths)
    print(f'Base: {base or bool(agents)}; agents: {agents}; Jenkins: {jenkins}', flush=True)
    def build(file, tag, **kwargs):
        args = ['docker', 'build', '--platform', 'linux/amd64', '-f', file, '-t', tag]
        for key, value in kwargs.items():
            args += ['--build-arg', f'{key}={value}']
        run(*args, '.')
    def check(image, kind, matrix=None):
        script = 'check_agent_base_tools.sh' if kind == 'base' else 'check_agent_software_tools.sh'
        args = ['docker', 'run', '--rm', '-v', '/var/run/docker.sock:/var/run/docker.sock',
                '-v', f'{os.getcwd()}/test/e2e/{script}:/tmp/{script}:ro',
                '-v', f'{os.getcwd()}/test/fixture/image-check/{kind}-agent:/tmp/{kind}-agent',
                '-e', f'AGENT_IMAGE={image}']
        if matrix:
            args += ['-e', f'SOFTWARE_MATRIX={matrix}']
        run(*args, image, '/bin/bash', f'/tmp/{script}')
    if inbound:
        image = 'pr-local/inbound-agent:smoke'
        build('jenkins-agent/inbound/Dockerfile', image)
        run('docker', 'run', '--rm', '--entrypoint', '/bin/bash', '-v',
            f'{os.getcwd()}/test/e2e/check_inbound_agent.sh:/tmp/check_inbound_agent.sh:ro',
            image, '/tmp/check_inbound_agent.sh')
    if base or agents:
        image = 'pr-local/jenkins-agent-base:latest-ubuntu-amd64'
        build('jenkins-agent/base/Dockerfile.ubuntu', image)
        check(image, 'base')
    versions = yaml.safe_load(open('version.yaml'))['Agent']
    for agent in agents:
        key = {'nodejs': 'NodeJs', 'python': 'Python', 'go': 'Golang', 'maven': 'Maven'}[agent]
        version = str(versions[key][0]).removeprefix('jdk')
        image = f'pr-local/{agent}:smoke'
        build(f'jenkins-agent/{agent}/Dockerfile', image, REGISTRY_REPO='pr-local',
              DISTRIBUTION='ubuntu', DISTRIBUTION_SUFFIX='-ubuntu', ARCH_SUFFIX='-amd64',
              RUNTIME='', **{('JAVA_VERSION' if agent == 'maven' else 'VERSION'): version})
        check(image, agent, f'{"java" if agent == "maven" else agent}-{version}')
    if jenkins:
        build('Dockerfile', 'pr-local/jenkins:smoke')


if __name__ == '__main__':
    main()
