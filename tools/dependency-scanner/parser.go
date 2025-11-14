package main

import (
	"fmt"
	"os"
	"path/filepath"

	sitter "github.com/smacker/go-tree-sitter"
	"github.com/smacker/go-tree-sitter/golang"
	"github.com/smacker/go-tree-sitter/javascript"
	"github.com/smacker/go-tree-sitter/python"
	"github.com/smacker/go-tree-sitter/typescript/tsx"
	"github.com/smacker/go-tree-sitter/typescript/typescript"
)

// Parser handles parsing files with tree-sitter
type Parser struct {
	languages map[string]*sitter.Language
}

// NewParser creates a new parser with specified languages
func NewParser(languageNames []string) (*Parser, error) {
	p := &Parser{
		languages: make(map[string]*sitter.Language),
	}

	// Map language names to their grammar
	languageMap := map[string]*sitter.Language{
		"typescript": typescript.GetLanguage(),
		"tsx":        tsx.GetLanguage(),
		"javascript": javascript.GetLanguage(),
		"go":         golang.GetLanguage(),
		"python":     python.GetLanguage(),
	}

	// Load requested languages
	for _, lang := range languageNames {
		if grammar, ok := languageMap[lang]; ok {
			if grammar == nil {
				continue
			}
			p.languages[lang] = grammar
		}
	}

	return p, nil
}

// Parse parses a file and returns a FileNode
func (p *Parser) Parse(filePath string) (*FileNode, error) {
	// Determine language from extension
	lang := p.detectLanguage(filePath)
	if lang == "" {
		return nil, fmt.Errorf("unsupported file type: %s", filePath)
	}

	// Get grammar
	grammar, ok := p.languages[lang]
	if !ok {
		return nil, fmt.Errorf("grammar not loaded for: %s (available: %v)", lang, p.getLoadedLanguages())
	}

	if grammar == nil {
		return nil, fmt.Errorf("grammar is nil for language: %s", lang)
	}

	// Read file
	content, err := os.ReadFile(filePath)
	if err != nil {
		return nil, err
	}

	// Create parser
	parser := sitter.NewParser()
	if parser == nil {
		return nil, fmt.Errorf("failed to create parser")
	}

	// Set language
	parser.SetLanguage(grammar)

	// Parse
	tree := parser.Parse(nil, content)
	if tree == nil {
		return nil, fmt.Errorf("failed to parse file")
	}
	defer tree.Close()

	// Create node
	node := &FileNode{
		Path:       filePath,
		Language:   lang,
		Imports:    []Import{},
		Exports:    []Export{},
		ImportedBy: []string{},
	}

	// Extract imports and exports using queries
	root := tree.RootNode()
	node.Imports = p.extractImports(root, content, lang)
	node.Exports = p.extractExports(root, content, lang)

	return node, nil
}

// getLoadedLanguages returns a list of loaded language names
func (p *Parser) getLoadedLanguages() []string {
	langs := []string{}
	for lang := range p.languages {
		langs = append(langs, lang)
	}
	return langs
}

// detectLanguage determines language from file extension
func (p *Parser) detectLanguage(filePath string) string {
	ext := filepath.Ext(filePath)
	switch ext {
	case ".tsx":
		// Check if tsx is loaded, otherwise fall back to typescript
		if _, ok := p.languages["tsx"]; ok {
			return "tsx"
		}
		return "typescript"
	case ".ts":
		return "typescript"
	case ".jsx":
		return "javascript"
	case ".js", ".mjs", ".cjs":
		return "javascript"
	case ".go":
		return "go"
	case ".py", ".pyi":
		return "python"
	default:
		return ""
	}
}

// extractImports extracts import statements from AST
func (p *Parser) extractImports(root *sitter.Node, content []byte, lang string) []Import {
	var imports []Import

	// Query patterns vary by language
	var queryStr string
	switch lang {
	case "typescript", "javascript":
		queryStr = `
			(import_statement) @import
			(import_clause) @import
		`
	case "go":
		queryStr = `(import_spec) @import`
	case "python":
		queryStr = `
			(import_statement) @import
			(import_from_statement) @import
		`
	default:
		return imports
	}

	// Create query
	query, err := sitter.NewQuery([]byte(queryStr), p.languages[lang])
	if err != nil {
		return imports
	}

	// Execute query
	cursor := sitter.NewQueryCursor()
	cursor.Exec(query, root)

	// Process matches
	for {
		match, ok := cursor.NextMatch()
		if !ok {
			break
		}

		for _, capture := range match.Captures {
			node := capture.Node
			text := content[node.StartByte():node.EndByte()]
			line := int(node.StartPoint().Row) + 1

			// Parse import text (simplified)
			imp := Import{
				Path:      string(text),
				Symbols:   []string{},
				IsDefault: false,
				Line:      line,
			}
			imports = append(imports, imp)
		}
	}

	return imports
}

// extractExports extracts export statements from AST
func (p *Parser) extractExports(root *sitter.Node, content []byte, lang string) []Export {
	var exports []Export

	// Query patterns vary by language
	var queryStr string
	switch lang {
	case "typescript", "javascript":
		queryStr = `
			(export_statement) @export
			(function_declaration) @export
			(class_declaration) @export
		`
	case "go":
		queryStr = `
			(function_declaration) @export
			(type_declaration) @export
		`
	case "python":
		queryStr = `
			(function_definition) @export
			(class_definition) @export
		`
	default:
		return exports
	}

	// Create query
	query, err := sitter.NewQuery([]byte(queryStr), p.languages[lang])
	if err != nil {
		return exports
	}

	// Execute query
	cursor := sitter.NewQueryCursor()
	cursor.Exec(query, root)

	// Process matches
	for {
		match, ok := cursor.NextMatch()
		if !ok {
			break
		}

		for _, capture := range match.Captures {
			node := capture.Node
			line := int(node.StartPoint().Row) + 1

			// Extract name (simplified - would need more sophisticated extraction)
			exp := Export{
				Name:      "exported_symbol",
				Type:      "function",
				IsDefault: false,
				Line:      line,
			}
			exports = append(exports, exp)
		}
	}

	return exports
}
