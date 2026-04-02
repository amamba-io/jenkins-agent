package main

# Test: storage-conf ConfigMap should be created when podman with storageConfig
test_storage_conf_created_when_podman_with_storage_config if {
    # Simulate storage-conf ConfigMap when ContainerRuntime is podman and storageConfig is set
    tests := {
        "apiVersion": "v1",
        "kind": "ConfigMap",
        "metadata": {"name": "storage-conf"},
        "data": {"storage.conf": "[storage]\ndriver = \"overlay\"\n"},
    }
    no_violations with input as tests
}

# Test: storage-conf ConfigMap with invalid content should be denied
test_storage_conf_invalid_content if {
    tests := {
        "apiVersion": "v1",
        "kind": "ConfigMap",
        "metadata": {"name": "storage-conf"},
        "data": {"storage.conf": "invalid content without [storage] section"},
    }
    deny["storage.conf must contain [storage] section"] with input as tests
}

# Test: insecure-registries ConfigMap should be created with insecureRegistries
test_insecure_registries_created if {
    tests := {
        "apiVersion": "v1",
        "kind": "ConfigMap",
        "metadata": {"name": "insecure-registries"},
        "data": {"registries.conf": "[[registry]]\nlocation = \"harbor.example.com\"\ninsecure = true\n"},
    }
    no_violations with input as tests
}

# Test: insecure-registries ConfigMap with valid registry format
test_insecure_registries_valid_format if {
    tests := {
        "apiVersion": "v1",
        "kind": "ConfigMap",
        "metadata": {"name": "insecure-registries"},
        "data": {"registries.conf": "[[registry]]\nlocation = \"10.6.182.195:5000\"\ninsecure = true\n"},
    }
    no_violations with input as tests
}
