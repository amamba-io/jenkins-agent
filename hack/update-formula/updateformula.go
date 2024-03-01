package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"net/http"
	"os"
	"slices"
	"strings"

	"gopkg.in/yaml.v2"
)

type formula struct {
	Bundle           interface{} `yaml:"bundle,omitempty"`
	WAR              interface{} `yaml:"war,omitempty"`
	Plugins          []plugin    `yaml:"plugins"`
	SystemProperties interface{} `yaml:"systemProperties,omitempty"`
	GroovyHooks      interface{} `yaml:"groovyHooks,omitempty"`
}

type plugin struct {
	GroupID    string `yaml:"groupId,omitempty"`
	ArtifactID string `yaml:"artifactId"`
	Source     source `yaml:"source"`
}

type source struct {
	Version string `yaml:"version"`
}

func (f *formula) Update(i int, p plugin) error {
	if len(f.Plugins) <= i {
		return errors.New("index out of range")
	}
	f.Plugins[i].Source.Version = p.Source.Version
	return nil
}

func (f *formula) RemovePlugins(indexes []int) error {
	slices.Sort(indexes)
	for i := len(indexes) - 1; i >= 0; i-- {
		j := indexes[i]
		log.Printf("Removed %s:%s", f.Plugins[j].ArtifactID, f.Plugins[j].Source.Version)
		f.Plugins = append(f.Plugins[:j], f.Plugins[j+1:]...)
	}
	return nil
}

func (f *formula) Append(p plugin) error {
	f.Plugins = append(f.Plugins, p)
	return nil
}

func (f *formula) Find(target plugin) *plugin {
	for i, plugin := range f.Plugins {
		if target.GroupID != "" && plugin.GroupID != "" && plugin.GroupID != target.GroupID {
			continue
		}
		if plugin.ArtifactID == target.ArtifactID {
			return &f.Plugins[i]
		}
	}
	return nil
}

// Updates formula.yaml according to plugins.txt specified in command-line
func main() {
	yamlFile, err := os.ReadFile("formula.yaml")
	if err != nil {
		log.Printf("yamlFile.Get err   #%v ", err)
	}

	origin, err := ParseFormula(yamlFile)
	if err != nil {
		log.Fatalf("parse formula.yaml error: %v", err)
	}

	pluginsFile, err := os.ReadFile("plugins.yaml")
	if err != nil {
		log.Printf("yamlFile.Get err   #%v ", err)
	}
	updated, err := ParseFormula(pluginsFile)
	if err != nil {
		log.Fatalf("parse plugins.yaml error: %v", err)
	}

	err = Update(origin, updated)
	if err != nil {
		log.Fatalf("Update error: %v", err)
	}
	data, err := yaml.Marshal(origin)
	if err != nil {
		log.Fatalf("Marshal error: %v", err)
	}
	err = os.WriteFile("formula.new.yaml", data, 0644)
	if err != nil {
		log.Fatalf("WriteFile error: %v", err)
	}
}

func ParseFormula(data []byte) (*formula, error) {
	c := &formula{}
	err := yaml.Unmarshal(data, c)
	if err != nil {
		return nil, err
	}
	return c, nil
}

// updates plugins versions if changed in target
// removes plugins not in target
// add plugins first seen in target
func Update(origin, target *formula) error {
	toRemove := []int{}
	for i, plugin := range origin.Plugins {
		dest := target.Find(plugin)
		if dest == nil {
			toRemove = append(toRemove, i)
		} else {
			if plugin.Source.Version != dest.Source.Version {
				log.Printf("Updated %s from %s to %s", plugin.ArtifactID, plugin.Source.Version, dest.Source.Version)
				if err := origin.Update(i, *dest); err != nil {
					return err
				}
			}
		}
	}
	for _, plugin := range target.Plugins {
		if origin.Find(plugin) == nil {
			if plugin.GroupID == "" {
				groupID := getPluginGroupID(plugin.ArtifactID)
				if groupID == "" {
					log.Printf("Warning: %s:%s groupID not found, place visit 'https://plugins.jenkins.io/<ArtifactID>/dependencies/'", plugin.ArtifactID, plugin.Source.Version)
				} else {
					plugin.GroupID = groupID
				}
			}

			err := origin.Append(plugin)
			if err != nil {
				return err
			}
			log.Printf("Added %s:%s", plugin.ArtifactID, plugin.Source.Version)
		}
	}
	err := origin.RemovePlugins(toRemove)
	return err
}

func getPluginGroupID(artifactID string) string {
	pluginSearchUrl := "https://plugins.jenkins.io/page-data/%s/dependencies/page-data.json"
	url := fmt.Sprintf(pluginSearchUrl, artifactID)
	request, err := http.NewRequest(http.MethodGet, url, nil)
	if err != nil {
		log.Printf("Error: %v", err)
		return ""
	}

	res, err := http.DefaultClient.Do(request)
	if err != nil {
		log.Printf("Error: %v", err)
		return ""
	}

	defer res.Body.Close()

	var resp PluginSearchResp
	err = json.NewDecoder(res.Body).Decode(&resp)
	if err != nil {
		log.Printf("Error: %v", err)
		return ""
	}

	grv := resp.Result.Data.JenkinsPlugin.Gav
	split := strings.Split(grv, ":")
	if len(split) != 3 {
		log.Printf("Error parse group %s for %s", grv, artifactID)
		return ""
	}
	return split[0]
}

type PluginSearchResp struct {
	Result struct {
		Data struct {
			JenkinsPlugin struct {
				Gav string `json:"gav"`
			} `json:"jenkinsPlugin"`
		} `json:"data"`
	} `json:"result"`
}
