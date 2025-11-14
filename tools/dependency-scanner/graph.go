package main

import (
	"encoding/json"
	"os"
	"time"
)

// DependencyGraph represents the complete dependency structure of a codebase
type DependencyGraph struct {
	Files       map[string]*FileNode `json:"Files"`
	Circular    [][]string           `json:"Circular"`
	DeadCode    []string             `json:"DeadCode"`
	LastUpdated time.Time            `json:"LastUpdated"`
}

// FileNode represents a single source file and its dependencies
type FileNode struct {
	Path       string   `json:"Path"`
	Language   string   `json:"Language"`
	Imports    []Import `json:"Imports"`
	Exports    []Export `json:"Exports"`
	ImportedBy []string `json:"ImportedBy"` // Files that import this file
}

// Import represents an import statement in a file
type Import struct {
	Path      string   `json:"Path"`      // "./auth" or "github.com/user/repo"
	Symbols   []string `json:"Symbols"`   // ["authenticateUser", "login"]
	IsDefault bool     `json:"IsDefault"` // true for default imports
	Line      int      `json:"Line"`      // Line number in source
}

// Export represents an exported symbol from a file
type Export struct {
	Name      string `json:"Name"`      // "authenticateUser"
	Type      string `json:"Type"`      // "function", "class", "const", "interface"
	IsDefault bool   `json:"IsDefault"` // true for default exports
	Line      int    `json:"Line"`      // Line number in source
}

// NewDependencyGraph creates a new empty dependency graph
func NewDependencyGraph() *DependencyGraph {
	return &DependencyGraph{
		Files:       make(map[string]*FileNode),
		Circular:    [][]string{},
		DeadCode:    []string{},
		LastUpdated: time.Now(),
	}
}

// SaveJSON saves the dependency graph to a JSON file
func (g *DependencyGraph) SaveJSON(outputPath string) error {
	data, err := json.MarshalIndent(g, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(outputPath, data, 0644)
}

// PrintStats prints statistics about the dependency graph
func (g *DependencyGraph) PrintStats() {
	// Language breakdown
	langCount := make(map[string]int)
	for _, node := range g.Files {
		langCount[node.Language]++
	}

	// Print summary
	if len(langCount) > 0 {
		first := true
		for lang, count := range langCount {
			if !first {
				print(", ")
			}
			printf("%s (%d)", lang, count)
			first = false
		}
		println()
	}
}
