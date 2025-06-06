# Chart 生成逻辑测试

本测试通过 [Conftest](https://www.conftest.dev/) 测试框架验证 Helm Chart 的生成逻辑是否符合预期。

由于从 0.4.0 版本开始，我们将chart拆分成了 `chart/jenkins` 和 `chart/jenkins-full` 两个部分，其中`chart/jenkins`只包含最核心的镜像，因此对应的测试用例可能也需要进行相应地拆分。我们按照如下的目录结构组织测试用例：

```bash
$ tree -L 3 test/rego/
test/rego/
├── container-registry
│   ├── common   <- 通用的规则
│   │   └── deny.rego
│   └── values.yaml
└── runtime
    ├── base    <- 针对 chart/jenkins 的测试
    │   └── deny.rego
    ├── full    <- 针对 chart/jenkins-full 的测试
    │   └── deny.rego
    └── values.yaml
```

最外层的目录用来包含一系列的测试用例，`base` 和 `full` 目录分别测试对于 `chart/jenkins` 和 `chart/jenkins-full` 的生成逻辑。`common` 则是一些通用规则，对于两个chart都会进行验证。