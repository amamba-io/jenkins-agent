# 如何升级Jenkins及插件

## 升级流程

1. 更新 jenkins 的 jar 包至新的版本；
2. 使用 [jenkins-plugin-manager](https://github.com/jenkinsci/plugin-installation-manager-tool) 基于 formula.core.yaml 下载所有插件；
3. 拷贝至 jenkins_home/plugins 目录，并重启jenkins；
4. 验证功能和需要单独升级的插件；
5. 使用 `jenkins-plugin-manager` 导出 plugins.yaml，使用脚本 `go run hack/update-formula` 更新formula.yaml；
6. 手动更新新添加的groupId （没有什么好办法，只能去github上手动翻对应插件的pom.xml）
7. 基于新的formula.yaml和 [jcli](https://github.com/jenkins-zh/jenkins-cl) 构建war包，验证功能；

