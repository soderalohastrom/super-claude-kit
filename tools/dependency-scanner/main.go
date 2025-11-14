package main

import (
	"flag"
	"fmt"
	"os"
	"time"
)

// Helper functions for output
func printf(format string, args ...interface{}) {
	fmt.Printf(format, args...)
}

func println(args ...interface{}) {
	fmt.Println(args...)
}

func print(args ...interface{}) {
	fmt.Print(args...)
}

func main() {
	// Define flags
	pathFlag := flag.String("path", ".", "Path to scan for dependencies")
	outputFlag := flag.String("output", "", "Output file path for JSON graph (default: .claude/dep-graph.json)")
	verboseFlag := flag.Bool("verbose", false, "Enable verbose output")
	versionFlag := flag.Bool("version", false, "Show version information")

	flag.Parse()

	// Show version
	if *versionFlag {
		fmt.Println("Super Claude Kit Dependency Scanner v2.0.0")
		fmt.Println("Built with tree-sitter for accurate multi-language parsing")
		os.Exit(0)
	}

	// Determine output path
	outputPath := *outputFlag
	if outputPath == "" {
		homeDir, err := os.UserHomeDir()
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error: Failed to get home directory: %v\n", err)
			os.Exit(1)
		}
		outputPath = fmt.Sprintf("%s/.claude/dep-graph.json", homeDir)
	}

	// Start timing
	startTime := time.Now()

	if *verboseFlag {
		fmt.Printf("Starting dependency scan...\n")
		fmt.Printf("Path: %s\n", *pathFlag)
		fmt.Printf("Output: %s\n", outputPath)
		fmt.Println()
	}

	// Create scanner
	scanner, err := NewScanner(*pathFlag, *verboseFlag)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: Failed to create scanner: %v\n", err)
		os.Exit(1)
	}

	// Scan directory
	if err := scanner.Scan(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: Scan failed: %v\n", err)
		os.Exit(1)
	}

	// Get graph
	graph := scanner.GetGraph()

	// Save to JSON
	if err := graph.SaveJSON(outputPath); err != nil {
		fmt.Fprintf(os.Stderr, "Error: Failed to save graph: %v\n", err)
		os.Exit(1)
	}

	// Calculate elapsed time
	elapsed := time.Since(startTime)

	// Print stats
	fmt.Printf("\n✅ Dependency graph saved to: %s\n", outputPath)
	fmt.Printf("📊 Files scanned: %d\n", len(graph.Files))

	if len(graph.Circular) > 0 {
		fmt.Printf("🔄 Circular dependencies: %d cycles\n", len(graph.Circular))
	} else {
		fmt.Printf("✅ No circular dependencies found\n")
	}

	if len(graph.DeadCode) > 0 {
		fmt.Printf("🗑️  Potentially unused files: %d\n", len(graph.DeadCode))
	} else {
		fmt.Printf("✅ No dead code detected\n")
	}

	// Print language breakdown
	graph.PrintStats()

	fmt.Printf("⏱️  Completed in: %.2fs\n", elapsed.Seconds())
}
