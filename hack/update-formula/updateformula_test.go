package main

import (
	"reflect"
	"testing"
)

func newTestPlugin(name, version, group string) plugin {
	return plugin{
		GroupID:    group,
		ArtifactID: name,
		Source: source{
			Version: version,
		},
	}
}

func testOriginFormula() *formula {
	return &formula{
		Plugins: []plugin{
			newTestPlugin("plugin-updated", "1.0.0", "org.jenkins-ci.plugins"),
			newTestPlugin("plugin-removed", "2.0.0", "org.jenkins-ci.plugins"),
			newTestPlugin("plugin-unchanged", "3.0.0", "org.jenkins-ci.plugins"),
		},
	}
}

func testTargetFormula() *formula {
	return &formula{
		Plugins: []plugin{
			newTestPlugin("plugin-updated", "1.1.0", ""),
			newTestPlugin("plugin-added", "4.0.0", ""),
			newTestPlugin("plugin-unchanged", "3.0.0", "org.jenkins-ci.plugins"),
		},
	}
}

func TestUpdate(t *testing.T) {
	type args struct {
		origin *formula
		target *formula
	}
	tests := []struct {
		name    string
		args    args
		want    *formula
		wantErr bool
	}{
		{
			name: "update",
			args: args{
				origin: testOriginFormula(),
				target: testTargetFormula(),
			},
			want: &formula{
				Plugins: []plugin{
					newTestPlugin("plugin-updated", "1.1.0", "org.jenkins-ci.plugins"),
					newTestPlugin("plugin-unchanged", "3.0.0", "org.jenkins-ci.plugins"),
					newTestPlugin("plugin-added", "4.0.0", ""),
				},
			},
			wantErr: false,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if err := Update(tt.args.origin, tt.args.target); (err != nil) != tt.wantErr {
				t.Errorf("Update() error = %v, wantErr %v", err, tt.wantErr)
			}
			if !reflect.DeepEqual(tt.args.origin, tt.want) {
				t.Errorf("Update() got = %v, want %v", tt.args.origin, tt.want)
			}
		})
	}
}
