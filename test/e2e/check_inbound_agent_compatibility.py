#!/usr/bin/env python3
"""Check the controller/plugin/official-agent combination without a Kubernetes cluster.

Creates only temporary containers, binds the test controller to loopback, and checks
plugin-generated JNLP settings, TCP/WebSocket connections and Pipeline execution.
"""
import argparse
import http.cookiejar
import json
import pathlib
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid

import yaml

parser = argparse.ArgumentParser()
parser.add_argument('--runtime', default='docker')
parser.add_argument('--formula', default='formula.yaml')
parser.add_argument('--controller', required=True)
parser.add_argument('--agent', required=True)
args = parser.parse_args()
prefix = 'inbound-compat-' + uuid.uuid4().hex[:10]
containers = []
with open(args.formula) as stream:
    formula = yaml.safe_load(stream)
expected_core = str(formula['war']['source']['version'])
expected_plugin = next(p['source']['version'] for p in formula['plugins']
                       if p['artifactId'] == 'kubernetes')
temporary = tempfile.TemporaryDirectory(prefix=prefix)
init = pathlib.Path(temporary.name) / 'init.groovy'
init.write_text('''
import jenkins.model.Jenkins
import hudson.security.SecurityRealm
import hudson.security.AuthorizationStrategy

def j = Jenkins.get()
j.setSecurityRealm(SecurityRealm.NO_AUTHENTICATION)
j.setAuthorizationStrategy(AuthorizationStrategy.UNSECURED)
j.setNumExecutors(0)
j.setSlaveAgentPort(50000)
j.getUpdateCenter().getSites().clear()
j.save()
println('COMPAT_CONTROLLER_INITIALIZED')
''')
init.chmod(0o644)

def run(*cmd):
    return subprocess.check_output([args.runtime, *cmd], text=True).strip()

opener = urllib.request.build_opener(
    urllib.request.ProxyHandler({}),
    urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))

def request(path, data=None):
    headers = {}
    if data is not None:
        crumb = json.loads(request('/crumbIssuer/api/json'))
        headers[crumb['crumbRequestField']] = crumb['crumb']
        data = urllib.parse.urlencode(data).encode()
    req = urllib.request.Request(url + path, data=data, headers=headers)
    return opener.open(req, timeout=90).read().decode()

def groovy(script):
    result = request('/scriptText', {'script': script})
    for line in result.splitlines():
        if line.startswith('COMPAT_RESULT='):
            return json.loads(line.removeprefix('COMPAT_RESULT='))
    raise RuntimeError(result)

try:
    containers.append(prefix)
    run('run', '-d', '--name', prefix, '-p', '127.0.0.1::8080',
        '-e', 'JAVA_OPTS=-Djenkins.install.runSetupWizard=false',
        '-v', f'{init}:/var/jenkins_home/init.groovy.d/compat.groovy:ro',
        args.controller)
    url = 'http://' + run('port', prefix, '8080/tcp')
    deadline = time.monotonic() + 300
    while True:
        try:
            request('/login')
            break
        except (urllib.error.URLError, OSError):
            if time.monotonic() > deadline:
                raise RuntimeError('Controller startup timed out')
            time.sleep(2)
    setup = '''
import jenkins.model.Jenkins
import jenkins.slaves.RemotingVersionInfo
import hudson.slaves.JNLPLauncher
import hudson.slaves.RetentionStrategy
import hudson.util.VersionNumber
import org.csanchez.jenkins.plugins.kubernetes.*

def j = Jenkins.get()
def plugin = j.pluginManager.getPlugin('kubernetes')
assert plugin != null && plugin.isActive()
assert Jenkins.VERSION == EXPECTED_CORE
assert plugin.version == EXPECTED_PLUGIN
assert new VersionNumber(Jenkins.VERSION).compareTo(new VersionNumber(plugin.requiredCoreVersion)) >= 0
jenkins.model.JenkinsLocationConfiguration.get().setUrl('http://127.0.0.1:8080/')
def cloud = new KubernetesCloud('compat')
cloud.setServerUrl('http://127.0.0.1:65534')
cloud.setNamespace('compat')
cloud.setJenkinsUrl('http://127.0.0.1:8080/')
j.clouds.add(cloud)
println('COMPAT_RESULT=' + groovy.json.JsonOutput.toJson([
  core: Jenkins.VERSION, plugin: plugin.version, requiredCore: plugin.requiredCoreVersion,
  embeddedRemoting: RemotingVersionInfo.getEmbeddedVersion().toString(),
  minimumRemoting: RemotingVersionInfo.getMinimumSupportedVersion().toString()
]))
'''
    setup = setup.replace('EXPECTED_CORE', json.dumps(expected_core))
    setup = setup.replace('EXPECTED_PLUGIN', json.dumps(expected_plugin))
    print('Controller combination:', groovy(setup), flush=True)
    for mode in ['tcp', 'websocket']:
        script = '''
import jenkins.model.Jenkins
import hudson.slaves.JNLPLauncher
import hudson.slaves.RetentionStrategy
import org.csanchez.jenkins.plugins.kubernetes.*
def j = Jenkins.get()
def cloud = j.clouds.getByName('compat')
cloud.setWebSocket(MODE == 'websocket')
def template = new PodTemplate()
template.setName('compat-' + MODE)
template.setLabel('compat-' + MODE)
def container = new ContainerTemplate('jnlp', IMAGE)
container.setWorkingDir('/home/jenkins/agent')
container.setArgs('${computer.jnlpmac} ${computer.name}')
template.setContainers([container])
cloud.addTemplate(template)
def node = KubernetesSlave.builder().name('compat-' + MODE).cloud(cloud).podTemplate(template)
    .computerLauncher(new JNLPLauncher()).retentionStrategy(new RetentionStrategy.Always()).build()
j.addNode(node)
def pod = new PodTemplateBuilder(template, node).build()
// Keep the generated Pod in memory; this test does not provision through a Kubernetes API.
node.assignPod(pod)
def agent = pod.spec.containers.find { it.name == 'jnlp' }
assert agent.image == IMAGE
assert agent.env.find { it.name == 'JENKINS_SECRET' }?.value
println('COMPAT_RESULT=' + groovy.json.JsonOutput.toJson([
  name: node.nodeName, env: agent.env.collectEntries { [(it.name):it.value] }
]))
'''.replace('MODE', json.dumps(mode)).replace('IMAGE', json.dumps(args.agent))
        settings = groovy(script)
        name = prefix + '-' + mode
        containers.append(name)
        cmd = ['run', '-d', '--name', name, '--network', 'container:' + prefix]
        for key, value in settings['env'].items():
            if value is not None:
                cmd += ['-e', key + '=' + value]
        # Same positional args used by the chart, in addition to plugin-injected environment.
        cmd += [args.agent, settings['env']['JENKINS_SECRET'], settings['name']]
        run(*cmd)
        deadline = time.monotonic() + 90
        while True:
            status = json.loads(request('/computer/' + settings['name'] + '/api/json?tree=offline'))
            if not status['offline']:
                break
            if time.monotonic() > deadline:
                raise RuntimeError('Agent connection timed out: ' + mode + '\n' + run('logs', name))
            time.sleep(2)
        execution = '''
import jenkins.model.Jenkins
import org.jenkinsci.plugins.workflow.job.WorkflowJob
import org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition
def j = Jenkins.get()
def job = j.createProject(WorkflowJob, 'compat-job-' + MODE)
job.definition = new CpsFlowDefinition("node('compat-MODE_NAME') { sh 'printf COMPAT_PIPELINE_OK; java -version' }",true)
def build = job.scheduleBuild2(0).get(60, java.util.concurrent.TimeUnit.SECONDS)
assert build.result.toString() == 'SUCCESS' : build.getLog(100).join('\\n')
assert build.getLog(100).join('\\n').contains('COMPAT_PIPELINE_OK')
def computer = j.getComputer('compat-' + MODE)
assert new hudson.util.VersionNumber(computer.getSlaveVersion()).compareTo(jenkins.slaves.RemotingVersionInfo.getMinimumSupportedVersion()) >= 0
assert computer.getSystemProperties()['java.specification.version'] == '21'
println('COMPAT_RESULT=' + groovy.json.JsonOutput.toJson([
  transport: MODE, build: build.result.toString(), agentRemoting: computer.getSlaveVersion(),
  computerType: computer.class.name
]))
'''.replace('MODE_NAME', mode).replace('MODE', json.dumps(mode))
        print('Connection and Pipeline:', groovy(execution), flush=True)
        run('rm', '-f', '-v', name)
        containers.remove(name)
finally:
    if sys.exc_info()[0] is not None:
        for name in containers:
            logs = subprocess.run([args.runtime, 'logs', '--tail', '100', name],
                                  text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            print(name + ':\n' + logs.stdout, file=sys.stderr)
    for name in reversed(containers):
        subprocess.run([args.runtime, 'rm', '-f', '-v', name],
                       stdout=subprocess.DEVNULL, check=False)

    temporary.cleanup()
