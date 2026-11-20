# ESLint Complete Guide

## Table of Contents

1. [What Is ESLint](#1-what-is-eslint)
2. [Why Use ESLint](#2-why-use-eslint)
3. [Installation](#3-installation)
4. [Configuration](#4-configuration)
5. [Core Concepts](#5-core-concepts)
6. [Usage Guide](#6-usage-guide)
7. [Rule Reference](#7-rule-reference)
8. [Custom Rules & Plugins](#8-custom-rules--plugins)
9. [Integration](#9-integration)
10. [Security Considerations](#10-security-considerations)
11. [Troubleshooting](#11-troubleshooting)
12. [Tips & Best Practices](#12-tips--best-practices)
13. [Command Reference](#13-command-reference)
14. [Configuration Reference](#14-configuration-reference)
15. [Real-World Examples](#15-real-world-examples-contoso-pet-store)
16. [Further Reading](#16-further-reading)

---

## 1. What Is ESLint

ESLint is a pluggable and configurable linter tool for identifying and reporting on patterns in JavaScript (and TypeScript) code. It helps developers find and fix problems, enforce code style, and maintain consistent code quality across projects.

### Key Characteristics

- **Pluggable architecture**: Extensible via rules, plugins, and processors
- **Configurable**: Fine-grained control via configuration files
- **Framework-aware**: Rules can understand React, Vue, Angular, etc.
- **TypeScript support**: Full TypeScript support via `@typescript-eslint`
- **Auto-fix**: Many issues can be automatically fixed
- **Modern**: Supports ESM, TypeScript, JSX, and latest ECMAScript features
- **Performance**: Parallel processing, caching, and incremental linting
- **Rich ecosystem**: 2000+ rules via official and community plugins
- **Code style**: Also serves as a formatter via `eslint --fix` and Prettier integration

### History

ESLint was created by Nicholas C. Zakas in 2013. It was the first linter built entirely as a plugin system, allowing every rule to be customized or replaced. ESLint gained widespread adoption after JSHint and JSLint fell out of favor, and it became the de facto standard JavaScript linter.

**Key milestones:**
- 2013: Initial release
- 2016: ES6 support
- 2019: Flat config system introduced (experimental)
- 2020: v7.0.0 — dropped Node.js 8 support
- 2022: v8.0.0 — flat config became default
- 2024: v9.0.0 — flat config only, removed legacy `.eslintrc`

### Architecture

```
┌─────────────────────────────────────────┐
│              ESLint Core                │
├─────────────────────────────────────────┤
│  Parser                                 │
│  ├─ Espree (default JS parser)          │
│  ├─ @typescript-eslint/parser           │
│  ├─ @babel/eslint-parser               │
│  └─ Custom parsers                      │
├─────────────────────────────────────────┤
│  Rule Engine                            │
│  ├─ AST traversal (visitor pattern)     │
│  ├─ 200+ built-in rules                 │
│  ├─ Plugin rules                        │
│  └─ Custom rules                        │
├─────────────────────────────────────────┤
│  Code Fixers                            │
│  ├─ Auto-fix (fixable rules)            │
│  ├─ Suggestions (manual fixes)          │
│  └─ Prettier integration                │
├─────────────────────────────────────────┤
│  Processors & Extensions                │
│  ├─ File processors (.vue, .md)         │
│  ├─ Plugin extensions                   │
│  └─ Flat config system                  │
└─────────────────────────────────────────┘
```

### ESLint v9 (Flat Config)

ESLint v9 introduced the "flat config" system as the default, replacing the legacy `.eslintrc` format:

```javascript
// eslint.config.js (flat config)
import js from "@eslint/js";
import tseslint from "typescript-eslint";

export default [
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    rules: {
      "no-unused-vars": "error",
      "no-console": "warn",
    },
  },
];
```

### Rule Severity Levels

| Level | Meaning | Exit Code |
|-------|---------|-----------|
| `off` / `0` | Rule disabled | — |
| `warn` / `1` | Warning (does not fail CI) | 0 |
| `error` / `2` | Error (fails CI) | 1 |

---

## 2. Why Use ESLint

### The Problem

Without a linter, JavaScript/TypeScript codebases accumulate:

1. **Bugs**: Unused variables, undefined references, type errors
2. **Security issues**: `eval()`, `innerHTML`, `dangerouslySetInnerHTML`
3. **Inconsistency**: Mixed formatting, naming conventions, code patterns
4. **Dead code**: Unreachable code, unused imports, duplicate code
5. **Maintainability**: Complex functions, deeply nested code, long files

### Why ESLint Over Alternatives

| Feature | ESLint | JSHint | JSLint | Biome |
|---------|--------|--------|--------|-------|
| Plugins | 2000+ | Limited | None | Limited |
| TypeScript | Yes | No | No | Yes |
| Auto-fix | Yes | Limited | No | Yes |
| React/Vue/Angular | Yes | Limited | No | Partial |
| Flat config | Yes | No | No | Yes |
| Custom rules | Yes | No | No | Limited |
| Performance | Fast | Fast | Fast | Very fast |
| Prettier integration | Yes | No | No | Built-in |

### Use Cases

1. **Bug prevention**: Catch errors before runtime
2. **Code review**: Automated review in PRs
3. **Team consistency**: Enforce shared coding standards
4. **Security**: Prevent common vulnerabilities
5. **Refactoring**: Find dead code, unused imports
6. **Education**: Learn JavaScript best practices
7. **TypeScript**: Enforce TypeScript-specific rules

---

## 3. Installation

### Method 1: npm (Recommended)

```bash
# Local installation (recommended)
npm install --save-dev eslint

# Global installation (not recommended for projects)
npm install -g eslint

# Initialize ESLint
npx eslint --init
```

### Method 2: yarn

```bash
yarn add --dev eslint
yarn eslint --init
```

### Method 3: pnpm

```bash
pnpm add -D eslint
pnpm eslint --init
```

### Method 4: ESLint Installer Script

```bash
# Official installer (detects package manager automatically)
npm init @eslint/config@latest

# Or with specific options
npm init @eslint/config@latest -- --style guide recommended
```

### Method 5: Deno

```bash
# ESLint works with Deno via deno_lint or npm specifier
deno run -A npm:eslint@9 eslint.config.js
```

### Plugin Installation

```bash
# TypeScript
npm install --save-dev typescript-eslint @typescript-eslint/parser

# React
npm install --save-dev eslint-plugin-react eslint-plugin-react-hooks eslint-plugin-react-refresh

# Vue
npm install --save-dev eslint-plugin-vue

# Angular
npm install --save-dev @angular-eslint/eslint-plugin @angular-eslint/eslint-plugin-template

# Prettier integration
npm install --save-dev eslint-config-prettier eslint-plugin-prettier

# Import ordering
npm install --save-dev eslint-plugin-import

# Security
npm install --save-dev eslint-plugin-security

# Node.js
npm install --save-dev eslint-plugin-n

# JSX a11y (accessibility)
npm install --save-dev eslint-plugin-jsx-a11y
```

### Editor Integration

**VS Code:**
```
Extension: ESLint
Publisher: Microsoft
```

**Vim/Neovim (via ALE):**
```vim
" .vimrc or init.vim
let g:ale_linters = {'javascript': ['eslint'], 'typescript': ['eslint']}
let g:ale_fixers = {'javascript': ['eslint'], 'typescript': ['eslint']}
```

**IntelliJ IDEA:**
1. Settings → Plugins → ESLint
2. Enable ESLint in Settings → Languages & Frameworks → JavaScript → Code Quality Tools → ESLint

---

## 4. Configuration

### Flat Config (ESLint v9+)

```javascript
// eslint.config.js
import js from "@eslint/js";
import tseslint from "typescript-eslint";
import react from "eslint-plugin-react";
import reactHooks from "eslint-plugin-react-hooks";
import importPlugin from "eslint-plugin-import";

export default [
  // Global ignores
  {
    ignores: [
      "dist/**",
      "node_modules/**",
      "build/**",
      "coverage/**",
      "*.min.js",
    ],
  },

  // Base recommended rules
  js.configs.recommended,

  // TypeScript recommended rules
  ...tseslint.configs.recommended,

  // Main configuration
  {
    files: ["**/*.{js,jsx,ts,tsx}"],
    plugins: {
      react,
      "react-hooks": reactHooks,
      import: importPlugin,
    },
    rules: {
      // Possible errors
      "no-console": "warn",
      "no-debugger": "error",
      "no-alert": "warn",
      "no-unused-vars": "off",  // Use TypeScript version
      "@typescript-eslint/no-unused-vars": "error",

      // Best practices
      "eqeqeq": ["error", "always"],
      "no-eval": "error",
      "no-implied-eval": "error",
      "no-new-func": "error",
      "no-return-await": "warn",

      // Variables
      "no-shadow": "off",
      "@typescript-eslint/no-shadow": "error",
      "no-use-before-define": "off",
      "@typescript-eslint/no-use-before-define": "error",

      // Style
      "semi": ["error", "always"],
      "quotes": ["error", "double", { avoidEscape: true }],
      "indent": ["error", 2],
      "no-trailing-spaces": "error",
      "eol-last": "error",
      "comma-dangle": ["error", "always-multiline"],

      // React
      "react/jsx-uses-react": "error",
      "react/jsx-uses-vars": "error",
      "react/jsx-key": "error",
      "react/no-direct-mutation-state": "error",
      "react-hooks/rules-of-hooks": "error",
      "react-hooks/exhaustive-deps": "warn",

      // Import
      "import/no-unresolved": "error",
      "import/named": "error",
      "import/default": "error",
      "import/namespace": "error",
      "import/order": ["error", {
        groups: ["builtin", "external", "internal", "parent", "sibling", "index"],
        "newlines-between": "always",
        alphabetize: { order: "asc" },
      }],
    },
    settings: {
      react: {
        version: "detect",
      },
    },
  },

  // TypeScript-specific config
  {
    files: ["**/*.{ts,tsx}"],
    rules: {
      // TypeScript specific
      "@typescript-eslint/explicit-function-return-type": "warn",
      "@typescript-eslint/no-explicit-any": "warn",
      "@typescript-eslint/no-non-null-assertion": "warn",
      "@typescript-eslint/consistent-type-imports": ["error", {
        prefer: "type-imports",
      }],
    },
  },

  // Test files override
  {
    files: ["**/*.{test,spec}.{js,jsx,ts,tsx}", "**/__tests__/**"],
    rules: {
      "no-console": "off",
      "@typescript-eslint/no-explicit-any": "off",
    },
  },

  // Config files override
  {
    files: ["*.config.{js,ts,mjs,cjs}"],
    rules: {
      "no-console": "off",
    },
  },
];
```

### Legacy Config (ESLint v8 and below)

```javascript
// .eslintrc.js (legacy format — deprecated in v9)
module.exports = {
  root: true,
  env: {
    browser: true,
    node: true,
    es2022: true,
    jest: true,
  },
  extends: [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "plugin:react/recommended",
    "plugin:react-hooks/recommended",
    "prettier",
  ],
  parser: "@typescript-eslint/parser",
  parserOptions: {
    ecmaVersion: "latest",
    sourceType: "module",
    ecmaFeatures: {
      jsx: true,
    },
  },
  plugins: ["@typescript-eslint", "react", "react-hooks"],
  rules: {
    // ... same rules as above
  },
  settings: {
    react: {
      version: "detect",
    },
  },
  overrides: [
    {
      files: ["**/*.{test,spec}.{js,jsx,ts,tsx}"],
      rules: {
        "no-console": "off",
      },
    },
  ],
};
```

### TypeScript Config Format

```typescript
// eslint.config.ts (TypeScript config — requires TypeScript parser)
import tseslint from "typescript-eslint";
import js from "@eslint/js";

export default tseslint.config(
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    rules: {
      "no-console": "warn",
      "@typescript-eslint/no-unused-vars": "error",
    },
  },
);
```

### JSON Config

```json
// eslint.config.json
{
  "files": ["**/*.{js,jsx,ts,tsx}"],
  "rules": {
    "no-console": "warn",
    "eqeqeq": "error",
    "semi": ["error", "always"]
  }
}
```

### YAML Config

```yaml
# eslint.config.yaml
files:
  - "**/*.{js,jsx,ts,tsx}"
rules:
  no-console: warn
  eqeqeq: error
  semi:
    - error
    - always
```

---

## 5. Core Concepts

### AST (Abstract Syntax Tree)

ESLint parses JavaScript/TypeScript into an AST, then traverses it to find violations:

```javascript
// This code becomes an AST with nodes like:
// Program > ExpressionStatement > CallExpression > Identifier("console")
console.log("hello");
```

Each rule defines a visitor function for specific node types:

```javascript
// Example: Custom rule that forbids console.log
export default {
  meta: {
    type: "problem",
    docs: {
      description: "Disallow console.log",
    },
    fixable: "code",
  },
  create(context) {
    return {
      CallExpression(node) {
        if (
          node.callee.type === "MemberExpression" &&
          node.callee.object.name === "console" &&
          node.callee.property.name === "log"
        ) {
          context.report({
            node,
            message: "Unexpected console.log statement",
            fix(fixer) {
              return fixer.remove(node);
            },
          });
        }
      },
    };
  },
};
```

### Rule Structure

Every ESLint rule has:

```javascript
export default {
  meta: {
    // Rule metadata
    type: "problem" | "suggestion" | "layout",
    docs: {
      description: "Rule description",
      category: "Best Practices",
      recommended: true,
      url: "https://eslint.org/docs/rule/rule-name",
    },
    fixable: "code" | "whitespace" | null,
    hasSuggestions: true | false,
    schema: [], // JSON Schema for rule options
    messages: {
      unexpected: "Unexpected value found",
    },
  },

  create(context) {
    // Return visitor functions
    return {
      Identifier(node) {
        // Called for every Identifier node
      },
      "Program:exit" {
        // Called when traversal is complete
      },
    };
  },
};
```

### Plugins

A plugin is a collection of rules, processors, and configurations:

```javascript
// eslint-plugin-example/index.js
import noConsoleLog from "./rules/no-console-log.js";
import noAlert from "./rules/no-alert.js";

export default {
  rules: {
    "no-console-log": noConsoleLog,
    "no-alert": noAlert,
  },
  configs: {
    recommended: {
      plugins: ["example"],
      rules: {
        "example/no-console-log": "error",
        "example/no-alert": "warn",
      },
    },
  },
  processors: {
    ".md": processMarkdown,
  },
};
```

### Processors

Processors extract code from non-JS files (e.g., Markdown, Vue):

```javascript
// Process code blocks in Markdown files
function processMarkdown(text) {
  const blocks = [];
  const regex = /```(?:js|javascript)\n([\s\S]*?)```/g;
  let match;

  while ((match = regex.exec(text)) !== null) {
    blocks.push({
      text: match[1],
      location: {
        start: { line: text.slice(0, match.index).split('\n').length },
        end: { line: text.slice(0, match.index + match[0].length).split('\n').length },
      },
    });
  }

  return blocks.map((block, index) => ({
    text: block.text,
    loc: block.location,
    meta: { name: `markdown-code-block-${index}` },
  }));
}
```

### Shared Configs

Predefined rule sets that can be extended:

```javascript
// eslint.config.js
import js from "@eslint/js";

export default [
  js.configs.recommended,  // ESLint recommended rules
  {
    rules: {
      // Override or add rules
    },
  },
];
```

**Common shared configs:**

| Config | Description |
|--------|-------------|
| `eslint:recommended` | ESLint recommended rules |
| `plugin:@typescript-eslint/recommended` | TypeScript rules |
| `plugin:react/recommended` | React rules |
| `plugin:react-hooks/recommended` | React hooks rules |
| `plugin:vue/recommended` | Vue rules |
| `plugin:prettier/recommended` | Prettier integration |
| `plugin:import/recommended` | Import rules |
| `plugin:jsx-a11y/recommended` | Accessibility rules |
| `plugin:security/recommended` | Security rules |
| `plugin:n/recommended` | Node.js rules |

---

## 6. Usage Guide

### Step 1: Initialize ESLint

```bash
# Interactive setup
npx eslint --init

# Or manual setup
npm install --save-dev eslint @eslint/js typescript-eslint
```

### Step 2: Lint Your Code

```bash
# Lint all files
npx eslint .

# Lint specific files
npx eslint src/**/*.{js,ts}

# Lint and show only errors
npx eslint . --quiet

# Lint and auto-fix
npx eslint . --fix

# Lint and generate report
npx eslint . --format json --output-file eslint-report.json
```

### Step 3: Fix Issues

```bash
# Auto-fix all fixable issues
npx eslint . --fix

# Fix specific files
npx eslint src/app.js --fix

# Fix only specific rules
npx eslint . --fix --rule '{"semi": "error"}'

# Dry run (show what would be fixed)
npx eslint . --fix-dry-run --format json
```

### Step 4: Configure for Your Project

```javascript
// eslint.config.js
import js from "@eslint/js";

export default [
  {
    ignores: ["dist/**", "node_modules/**", "build/**"],
  },
  js.configs.recommended,
  {
    files: ["**/*.{js,ts}"],
    rules: {
      "no-console": "warn",
      "no-unused-vars": "error",
      "eqeqeq": "error",
    },
  },
];
```

### Step 5: Add to package.json

```json
{
  "scripts": {
    "lint": "eslint .",
    "lint:fix": "eslint . --fix",
    "lint:check": "eslint . --max-warnings 0",
    "lint:report": "eslint . --format json --output-file eslint-report.json"
  }
}
```

### Step 6: CI/CD Integration

```yaml
# GitHub Actions
- name: Lint
  run: npm run lint:check

# Or with specific exit code handling
- name: Lint
  run: npx eslint . --max-warnings 0
```

### Step 7: Editor Setup

**VS Code settings.json:**
```json
{
  "eslint.validate": [
    "javascript",
    "typescript",
    "typescriptreact",
    "javascriptreact",
    "vue",
    "html"
  ],
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": "explicit"
  },
  "eslint.rules.customizations": [
    { "rule": "*", "severity": "warn" }
  ]
}
```

---

## 7. Rule Reference

### Possible Errors

| Rule | Description | Fixable |
|------|-------------|---------|
| `for-direction` | For loop update clause counter is in wrong direction | — |
| `getter-return` | Getter must return a value | — |
| `no-async-promise-executor` | Promise executor should not be async | — |
| `no-await-in-loop` | Disallow await inside of loops | — |
| `no-compare-neg-zero` | Disallow comparing against -0 | — |
| `no-cond-assign` | Disallow assignment in conditional expressions | — |
| `no-const-assign` | Disallow reassigning const variables | — |
| `no-constant-binary-expression` | Disallow expressions where the operation doesn't affect the value | — |
| `no-constant-condition` | Disallow constant expressions in conditions | — |
| `no-control-regex` | Disallow control characters in regular expressions | — |
| `no-debugger` | Disallow the use of `debugger` | hasSuggestions |
| `no-dupe-args` | Disallow duplicate arguments in function calls | — |
| `no-dupe-class-members` | Disallow duplicate class members | — |
| `no-dupe-else-if` | Disallow duplicate conditions in if-else-if chains | — |
| `no-dupe-keys` | Disallow duplicate keys in object literals | — |
| `no-duplicate-case` | Disallow duplicate case labels | — |
| `no-empty` | Disallow empty block statements | — |
| `no-empty-character-class` | Disallow empty character classes in regular expressions | — |
| `no-empty-pattern` | Disallow empty destructuring patterns | — |
| `no-ex-assign` | Disallow reassigning exceptions to `catch` parameters | — |
| `no-fallthrough` | Disallow fallthrough of `case` statements | hasSuggestions |
| `no-func-assign` | Disallow reassigning of function parameters | — |
| `no-import-assign` | Disallow assigning to imported bindings | — |
| `no-inner-declarations` | Disallow variable or function declarations in nested blocks | — |
| `no-invalid-regexp` | Disallow invalid regular expression strings in `RegExp` constructors | — |
| `no-irregular-whitespace` | Disallow irregular whitespace outside of strings and comments | — |
| `no-loss-of-precision` | Disallow literal numbers that lose precision | — |
| `no-misleading-character-class` | Disallow characters that are made with punctuation marks outside of brackets | — |
| `no-prototype-builtins` | Disallow calling some `Object.prototype` methods directly on objects | — |
| `no-unsafe-negation` | Disallow negating the left-hand side of relational operators | hasSuggestions |
| `no-unsafe-optional-chaining` | Disallow use of optional chaining in contexts where it may give unexpected results | hasSuggestions |
| `no-unused-private-class-members` | Disallow unused private class members | — |
| `no-unused-vars` | Disallow unused variables | hasSuggestions |
| `no-useless-backreference` | Disallow useless backreferences in regular expressions | — |
| `no-with` | Disallow `with` statements | — |
| `require-yield` | Disallow generator functions that do not have `yield` | — |
| `use-isnan` | Require calls to `isNaN()` when checking for `NaN` | hasSuggestions |
| `valid-typeof` | Enforce the consistent use of the `typeof` operator | — |

### Best Practices

| Rule | Description | Fixable |
|------|-------------|---------|
| `array-callback-return` | Enforce return statements in callbacks of array methods | hasSuggestions |
| `block-scoped-var` | Enforce the use of variables within the scope they are defined | — |
| `class-methods-use-this` | Enforce that class methods utilize `this` | hasSuggestions |
| `complexity` | Enforce a maximum cyclomatic complexity allowed in a program | — |
| `consistent-return` | Require `return` statements to either always or never specify values | — |
| `curly` | Enforce consistent brace style for all control statements | hasSuggestions |
| `default-case` | Require `default` cases in `switch` statements | hasSuggestions |
| `default-case-last` | Enforce default clauses in switch statements to be last | — |
| `dot-notation` | Enforce dot notation whenever possible | hasSuggestions |
| `eqeqeq` | Require the use of `===` and `!==` | hasSuggestions |
| `grouping-access-op-parens` | Disallow unnecessary parentheses around member expressions | hasSuggestions |
| `guard-for-in` | Require `for-in` loops to include an `hasOwnProperty` filter | — |
| `max-classes-per-file` | Enforce a maximum number of classes per file | hasSuggestions |
| `max-depth` | Enforce a maximum depth that blocks can be nested to | hasSuggestions |
| `max-lines` | Enforce a maximum number of lines per file | hasSuggestions |
| `max-lines-per-function` | Enforce a maximum number of lines of code in a function | hasSuggestions |
| `max-nested-callbacks` | Enforce a maximum depth that callbacks can be nested | hasSuggestions |
| `max-params` | Enforce a maximum number of parameters in function definitions | hasSuggestions |
| `max-statements` | Enforce a maximum number of statements allowed in function blocks | hasSuggestions |
| `no-alert` | Disallow the use of `alert`, `confirm`, and `prompt` | hasSuggestions |
| `no-case-declarations` | Disallow lexical declarations in case/default clauses | hasSuggestions |
| `no-constructor-return` | Disallow returning value from constructor | — |
| `no-else-return` | Disallow `else` blocks after `return` statements in `if` blocks | hasSuggestions |
| `no-empty-function` | Disallow empty functions | hasSuggestions |
| `no-empty-static-block` | Disallow empty static blocks | hasSuggestions |
| `no-eq-null` | Disallow `null` comparisons without type-checking operators | — |
| `no-eval` | Disallow the use of `eval()` | hasSuggestions |
| `no-extend-native` | Disallow extending native objects | — |
| `no-extra-bind` | Disallow unnecessary calls to `.bind()` | hasSuggestions |
| `no-extra-boolean-cast` | Disallow unnecessary boolean casts | hasSuggestions |
| `no-extra-label` | Disallow unnecessary labels | hasSuggestions |
| `no-extra-semi` | Disallow unnecessary semicolons | hasSuggestions |
| `no-floating-decimal` | Disallow leading or trailing decimal points in numeric literals | hasSuggestions |
| `no-global-assign` | Disallow assignments to native objects or read-only global variables | — |
| `no-implicit-coercion` | Disallow shorthand type conversions | hasSuggestions |
| `no-implied-eval` | Disallow implied `eval()` | hasSuggestions |
| `no-iterator` | Disallow the use of the `__iterator__` property | — |
| `no-labels` | Disallow labeled statements | hasSuggestions |
| `no-lone-blocks` | Disallow unnecessary nested blocks | hasSuggestions |
| `no-loop-func` | Disallow function declarations and expressions inside loop statements | hasSuggestions |
| `no-magic-numbers` | Disallow magic numbers | hasSuggestions |
| `no-multi-spaces` | Disallow multiple spaces | hasSuggestions |
| `no-multi-str` | Disallow multiline strings | — |
| `no-negated-condition` | Disallow negated conditions in if-else-if chains | hasSuggestions |
| `no-nested-ternary` | Disallow nested ternary expressions | hasSuggestions |
| `no-new` | Disallow `new` operators for side effects | — |
| `no-new-func` | Disallow `new` operators with the `Function` object | — |
| `no-new-wrappers` | Disallow `new` operators with the `String`, `Number`, and `Boolean` objects | — |
| `no-octal` | Disallow octal literals | — |
| `no-octal-escape` | Disallow octal escape sequences in string literals | — |
| `no-param-reassign` | Disallow reassigning function parameters | hasSuggestions |
| `no-proto` | Disallow the use of the `__proto__` property | — |
| `no-redeclare` | Disallow `var` redeclaration | — |
| `no-regex-spaces` | Disallow multiple spaces in regular expression literals | hasSuggestions |
| `no-return-assign` | Disallow assignment operators in `return` statements | — |
| `no-return-await` | Disallow unnecessary `return await` | hasSuggestions |
| `no-self-assign` | Disallow assignments where both sides are exactly the same | — |
| `no-self-compare` | Disallow comparisons where both sides are exactly the same | — |
| `no-sequences` | Disallow comma operator | — |
| `no-throw-literal` | Disallow throwing literals as exceptions | hasSuggestions |
| `no-unmodified-loop-condition` | Disallow unmodified loop conditions | hasSuggestions |
| `no-unneeded-ternary` | Disallow ternary operators when simpler alternatives exist | hasSuggestions |
| `no-unused-expressions` | Disallow unused expressions | hasSuggestions |
| `no-unused-labels` | Disallow unused labels | hasSuggestions |
| `no-useless-call` | Disallow unnecessary `.call()` and `.apply()` | — |
| `no-useless-catch` | Disallow unnecessary `catch` clauses | — |
| `no-useless-concat` | Disallow unnecessary concatenation of literals | — |
| `no-useless-constructor` | Disallow unnecessary constructors | — |
| `no-useless-else` | Disallow `else` blocks when the `if` block contains a `return` | hasSuggestions |
| `no-useless-rename` | Disallow renaming import, export, and destructured assignments to the same name | hasSuggestions |
| `no-useless-return` | Disallow unnecessary `return` statements | hasSuggestions |
| `no-var` | Require `let` or `const` instead of `var` | hasSuggestions |
| `no-void` | Disallow `void` operators | — |
| `no-warning-comments` | Disallow specified terms in comments | — |
| `no-with` | Disallow `with` statements | — |
| `operator-assignment` | Enforce operator assignment shorthand | hasSuggestions |
| `prefer-arrow-callback` | Require arrow functions as callbacks | hasSuggestions |
| `prefer-const` | Require `const` declarations for variables that are never reassigned | hasSuggestions |
| `prefer-destructuring` | Require destructuring from arrays and/or objects | hasSuggestions |
| `prefer-exponentiation-operator` | Disallow the use of `Math.pow` in favor of the `**` operator | hasSuggestions |
| `prefer-named-capture-group` | Disallow non-named capture groups in regular expressions | — |
| `prefer-promise-reject-errors` | Require using Error objects as Promise rejection reasons | hasSuggestions |
| `prefer-regex-literals` | Disallow the use of `Math.random()` | hasSuggestions |
| `radix` | Enforce the consistent use of the radix argument when using `parseInt()` | hasSuggestions |
| `require-await` | Disallow `async` functions which have no `await` expression | hasSuggestions |
| `sort-imports` | Enforce sorted import declarations within modules | hasSuggestions |
| `sort-keys` | Require object keys to be sorted | hasSuggestions |
| `sort-vars` | Require `const` declarations to be sorted alphabetically | hasSuggestions |
| `symbol-description` | Require symbol descriptions | — |
| `vars-on-top` | Require `var` declarations to be at the top of their scope | — |
| `yoda` | Disallow "Yoda" conditions | hasSuggestions |

### Strict Mode

| Rule | Description |
|------|-------------|
| `strict` | Require or disallow strict mode directives |

### Variables

| Rule | Description | Fixable |
|------|-------------|---------|
| `init-declarations` | Require or disallow initialization in variable declarations | — |
| `no-delete-var` | Disallow deleting variables | — |
| `no-label-var` | Disallow labels that are variable names | — |
| `no-restricted-globals` | Disallow specified global variables | hasSuggestions |
| `no-shadow` | Disallow variable declarations from shadowing variables in the outer scope | — |
| `no-shadow-restricted-names` | Disallow identifiers from shadowing restricted names | — |
| `no-undef` | Disallow the use of undeclared variables | hasSuggestions |
| `no-undef-init` | Disallow initializing variables to `undefined` | hasSuggestions |
| `no-undefined` | Disallow the use of `undefined` as an identifier | — |
| `no-unused-vars` | Disallow unused variables | hasSuggestions |
| `no-use-before-define` | Disallow the use of variables before they are defined | hasSuggestions |

### Stylistic Rules

| Rule | Description | Fixable |
|------|-------------|---------|
| `array-bracket-newline` | Enforce linebreaks after opening and before closing array brackets | hasSuggestions |
| `array-bracket-spacing` | Disallow or enforce spaces inside of brackets after open and before close | hasSuggestions |
| `array-element-newline` | Enforce line breaks between array elements | hasSuggestions |
| `block-spacing` | Disallow or enforce spaces inside of single-line blocks | hasSuggestions |
| `brace-style` | Enforce brace style for blocks | hasSuggestions |
| `camelcase` | Enforce camelcase naming convention | hasSuggestions |
| `capitalized-comments` | Enforce or disallow capitalization of the first letter of a comment | hasSuggestions |
| `comma-dangle` | Disallow or enforce trailing commas | hasSuggestions |
| `comma-spacing` | Enforce spacing after commas | hasSuggestions |
| `comma-style` | Enforce consistent comma style | hasSuggestions |
| `computed-property-spacing` | Enforce or disallow spaces inside computed property brackets | hasSuggestions |
| `consistent-this` | Enforce consistent naming when capturing the current execution context | hasSuggestions |
| `eol-last` | Enforce or disallow newline at the end of files | hasSuggestions |
| `func-call-spacing` | Disallow or enforce spaces between function identifiers and their invocations | hasSuggestions |
| `func-name-matching` | Require function names to match the name of the variable or property to which they are assigned | — |
| `func-names` | Require or disallow named `function` expressions | — |
| `func-style` | Enforce or disallow the use of the shorthand syntax for function definitions | hasSuggestions |
| `function-paren-newline` | Enforce line breaks between arguments of a function call | hasSuggestions |
| `generator-star-spacing` | Enforce spacing around the `*` in generator functions | hasSuggestions |
| `grouped-accessor-pairs` | Require grouped accessor pairs in class literals | hasSuggestions |
| `id-denylist` | Disallow specified identifiers | — |
| `id-length` | Enforce minimum and maximum identifier lengths | — |
| `id-match` | Require identifiers to match a specified regular expression | — |
| `implicit-arrow-linebreak` | Enforce the location of arrow function bodies | hasSuggestions |
| `indent` | Enforce consistent indentation | hasSuggestions |
| `jsx-quotes` | Enforce the consistent use of either double or single quotes in JSX attributes | hasSuggestions |
| `key-spacing` | Enforce consistent spacing between keys and values in object literal properties | hasSuggestions |
| `keyword-spacing` | Enforce consistent spacing before and after keywords | hasSuggestions |
| `linebreak-style` | Enforce consistent linebreak style | hasSuggestions |
| `lines-around-comment` | Require or disallow empty lines around comments | hasSuggestions |
| `lines-between-class-members` | Require or disallow an empty line between class members | hasSuggestions |
| `max-len` | Enforce a maximum line length | hasSuggestions |
| `max-statements-per-line` | Enforce a maximum number of statements allowed per line | hasSuggestions |
| `multiline-ternary` | Enforce newlines between operands of ternary expressions | hasSuggestions |
| `new-parens` | Enforce or disallow parentheses when invoking a constructor with no arguments | hasSuggestions |
| `newline-per-chained-call` | Require a newline after each call in a method chain | hasSuggestions |
| `no-confusing-arrow` | Disallow arrow functions where they could be confused with comparisons | hasSuggestions |
| `no-extra-parens` | Disallow unnecessary parentheses | hasSuggestions |
| `no-extra-semi` | Disallow unnecessary semicolons | hasSuggestions |
| `no-floating-decimal` | Disallow floating decimal points | hasSuggestions |
| `no-mixed-operators` | Disallow mixed operators without parentheses | hasSuggestions |
| `no-mixed-spaces-and-tabs` | Disallow mixed spaces and tabs for indentation | — |
| `no-multi-spaces` | Disallow multiple spaces | hasSuggestions |
| `no-multiple-empty-lines` | Disallow multiple empty lines | hasSuggestions |
| `no-tabs` | Disallow all tabs | — |
| `no-ternary` | Disallow ternary operators | hasSuggestions |
| `no-trailing-spaces` | Disallow trailing whitespace at the end of lines | hasSuggestions |
| `no-whitespace-before-property` | Disallow whitespace before properties | hasSuggestions |
| `nonblock-statement-body-position` | Enforce the location of single-line statements | hasSuggestions |
| `object-curly-newline` | Enforce consistent line breaks inside braces | hasSuggestions |
| `object-curly-spacing` | Enforce consistent spacing inside braces | hasSuggestions |
| `object-property-newline` | Enforce consistent line breaks between properties | hasSuggestions |
| `one-var` | Enforce variables to be declared either together or separately per function | hasSuggestions |
| `one-var-declaration-per-line` | Require newlines around variable declarations | hasSuggestions |
| `operator-linebreak` | Enforce consistent linebreak style around operators | hasSuggestions |
| `padded-blocks` | Disallow or enforce padding inside of blocks | hasSuggestions |
| `padding-line-between-statements` | Require or disallow padding lines between statements | hasSuggestions |
| `quote-props` | Disallow or enforce quotes around object literal property names | hasSuggestions |
| `quotes` | Enforce the consistent use of either backticks, double, or single quotes | hasSuggestions |
| `semi` | Require or disallow semicolons instead of ASI | hasSuggestions |
| `semi-spacing` | Enforce spacing before and after semicolons | hasSuggestions |
| `semi-style` | Enforce location of semicolons | hasSuggestions |
| `space-before-blocks` | Enforce consistent spacing before blocks | hasSuggestions |
| `space-before-function-paren` | Enforce consistent spacing before `function` definition opening paren | hasSuggestions |
| `space-in-parens` | Enforce consistent spacing inside parentheses | hasSuggestions |
| `space-infix-ops` | Require spacing around infix operators | hasSuggestions |
| `space-unary-ops` | Enforce consistent spacing before or after unary operators | hasSuggestions |
| `spaced-comment` | Enforce consistent spacing after the `//` or `/*` in a comment | hasSuggestions |
| `switch-colon-spacing` | Enforce spacing around colons in switch case clauses | hasSuggestions |
| `template-curly-spacing` | Require or disallow spacing inside of template curly braces | hasSuggestions |
| `template-tag-spacing` | Enforce spacing between tag and template literal | hasSuggestions |
| `unicode-bom` | Require or disallow the Unicode BOM | hasSuggestions |
| `wrap-iife` | Require parentheses around immediate function invocations | hasSuggestions |
| `wrap-regex` | Require or disallow parentheses around regex literals | hasSuggestions |
| `yield-star-spacing` | Enforce spacing around the `*` in `yield*` expressions | hasSuggestions |

---

## 8. Custom Rules & Plugins

### Creating a Custom Rule

```javascript
// rules/no-foo-bar.js
export default {
  meta: {
    type: "problem",
    docs: {
      description: "Disallow the use of 'foo-bar' variable name",
      category: "Best Practices",
      recommended: false,
    },
    fixable: "code",
    hasSuggestions: true,
    schema: [
      {
        type: "object",
        properties: {
          allowPattern: {
            type: "string",
            description: "Regex pattern to allow",
          },
        },
        additionalProperties: false,
      },
    ],
    messages: {
      unexpected:
        "Unexpected variable name '{{ name }}'. Use a descriptive name instead.",
    },
  },

  create(context) {
    const options = context.options[0] || {};
    const allowPattern = options.allowPattern
      ? new RegExp(options.allowPattern)
      : null;

    return {
      Identifier(node) {
        if (node.name === "foo-bar") {
          if (allowPattern && allowPattern.test(context.getFilename())) {
            return;
          }

          context.report({
            node,
            messageId: "unexpected",
            data: { name: node.name },
            fix(fixer) {
              return fixer.replaceText(node, "descriptiveName");
            },
            suggest: [
              {
                desc: "Rename to 'descriptiveName'",
                fix(fixer) {
                  return fixer.replaceText(node, "descriptiveName");
                },
              },
            ],
          });
        }
      },
    };
  },
};
```

### Creating a Plugin

```javascript
// eslint-plugin-contoso/index.js
import noFooBar from "./rules/no-foo-bar.js";
import noEval from "./rules/no-eval.js";

export default {
  rules: {
    "no-foo-bar": noFooBar,
    "no-eval": noEval,
  },
  configs: {
    recommended: {
      plugins: ["contoso"],
      rules: {
        "contoso/no-foo-bar": "error",
        "contoso/no-eval": "error",
      },
    },
    strict: {
      plugins: ["contoso"],
      rules: {
        "contoso/no-foo-bar": ["error", { allowPattern: "\\.test\\.ts$" }],
        "contoso/no-eval": "error",
      },
    },
  },
  processors: {
    ".vue": processVue,
  },
};
```

### Registering a Plugin

```javascript
// eslint.config.js
import contoso from "eslint-plugin-contoso";

export default [
  {
    plugins: {
      contoso,
    },
    rules: {
      "contoso/no-foo-bar": "error",
      "contoso/no-eval": "error",
    },
  },
];
```

### Writing Rule Tests

```javascript
// tests/rules/no-foo-bar.test.js
import { RuleTester } from "eslint";
import noFooBar from "../../rules/no-foo-bar.js";

const ruleTester = new RuleTester({
  languageOptions: {
    ecmaVersion: 2022,
    sourceType: "module",
  },
});

ruleTester.run("no-foo-bar", noFooBar, {
  valid: [
    "const descriptiveName = 42;",
    "let foo = 1;",
    { code: "const fb = 1;", options: [{ allowPattern: "\\.test\\.ts$" }] },
  ],
  invalid: [
    {
      code: "const foo-bar = 42;",
      errors: [
        {
          messageId: "unexpected",
          data: { name: "foo-bar" },
          type: "Identifier",
        },
      ],
      output: "const descriptiveName = 42;",
    },
    {
      code: "let foo-bar = 1;",
      errors: [{ messageId: "unexpected" }],
      output: "let descriptiveName = 1;",
    },
  ],
});
```

---

## 9. Integration

### Pre-commit Framework

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/pre-commit/mirrors-eslint
    rev: v9.0.0
    hooks:
      - id: eslint
        args: ['--fix', '--max-warnings', '0']
        additional_dependencies:
          - eslint@9.0.0
          - typescript-eslint@8.0.0
          - eslint-plugin-react@7.34.0
```

### GitHub Actions

```yaml
# .github/workflows/eslint.yml
name: ESLint

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  eslint:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 20

      - name: Install dependencies
        run: npm ci

      - name: Run ESLint
        run: npm run lint:check

      - name: Run ESLint with fix (for PR)
        if: github.event_name == 'pull_request'
        run: npx eslint . --fix
```

### GitLab CI

```yaml
# .gitlab-ci.yml
eslint:
  stage: lint
  image: node:20
  script:
    - npm ci
    - npm run lint:check
  allow_failure: false
```

### Jenkins Pipeline

```groovy
pipeline {
    agent any

    stages {
        stage('ESLint') {
            steps {
                sh 'npm ci'
                sh 'npm run lint:check'
            }
            post {
                failure {
                    echo 'ESLint found issues'
                }
            }
        }
    }
}
```

### Prettier Integration

```bash
npm install --save-dev eslint-config-prettier eslint-plugin-prettier
```

```javascript
// eslint.config.js
import prettier from "eslint-config-prettier";
import eslintPluginPrettier from "eslint-plugin-prettier";

export default [
  prettier,
  {
    plugins: {
      prettier: eslintPluginPrettier,
    },
    rules: {
      "prettier/prettier": "error",
    },
  },
];
```

### VS Code Settings

```json
// .vscode/settings.json
{
  "eslint.validate": [
    "javascript",
    "typescript",
    "typescriptreact",
    "javascriptreact",
    "vue"
  ],
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": "explicit"
  },
  "editor.formatOnSave": false,
  "eslint.rules.customizations": [
    { "rule": "*", "severity": "warn" }
  ],
  "eslint.options": {
    "cache": true,
    "cacheLocation": "${workspaceFolder}/.eslintcache"
  }
}
```

### Webpack Integration

```javascript
// webpack.config.js
import ESLintPlugin from "eslint-webpack-plugin";

export default {
  plugins: [
    new ESLintPlugin({
      extensions: ["js", "jsx", "ts", "tsx"],
      fix: true,
      lintDirtyModulesOnly: true,
    }),
  ],
};
```

### Vite Integration

```javascript
// vite.config.ts
import eslint from "vite-plugin-eslint";

export default {
  plugins: [
    eslint({
      fix: true,
      cache: true,
    }),
  ],
};
```

### Create React App

CRA includes ESLint by default:

```json
// package.json
{
  "eslintConfig": {
    "extends": [
      "react-app",
      "react-app/jest"
    ]
  }
}
```

### Next.js

```javascript
// .eslintrc.json (Next.js v12 and below — legacy)
{
  "extends": "next/core-web-vitals"
}

// eslint.config.js (Next.js v13+ with flat config)
import { dirname } from "path";
import { fileURLToPath } from "url";
import { FlatCompat } from "@eslint/eslintrc";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const compat = new FlatCompat({
  baseDirectory: __dirname,
});

export default [
  ...compat.extends("next/core-web-vitals"),
];
```

---

## 10. Security Considerations

### Security Rules

```javascript
// eslint.config.js
import security from "eslint-plugin-security";

export default [
  security.configs.recommended,
  {
    rules: {
      "security/detect-object-injection": "warn",
      "security/detect-non-literal-regexp": "warn",
      "security/detect-non-literal-fs-filename": "warn",
      "security/detect-eval-with-expression": "error",
      "security/detect-no-csrf-before-method-override": "error",
      "security/detect-possible-timing-attacks": "warn",
      "security/detect-pseudoRandomBytes": "warn",
    },
  },
];
```

### Common Security Issues Caught

| Rule | Issue | Risk |
|------|-------|------|
| `no-eval` | `eval()` usage | Code injection |
| `no-implied-eval` | Indirect `eval()` | Code injection |
| `no-new-func` | `new Function()` | Code injection |
| `no-script-url` | `javascript:` URLs | XSS |
| `security/detect-eval-with-expression` | Dynamic `eval()` | Code injection |
| `security/detect-object-injection` | Dynamic property access | Prototype pollution |
| `security/detect-non-literal-regexp` | Dynamic regex | ReDoS |

### Secure Coding Rules

```javascript
// Good security practices
{
  rules: {
    "no-eval": "error",
    "no-implied-eval": "error",
    "no-new-func": "error",
    "no-script-url": "error",
    "no-caller": "error",
    "no-extend-native": "error",
    "no-global-assign": "error",
    "no-proto": "error",
    "eqeqeq": ["error", "always"],
    "no-implicit-globals": "error",
    "no-labels": "error",
    "no-octal": "error",
    "no-void": "error",
    "no-with": "error",
    "radix": "error",
  },
}
```

### Preventing XSS

```javascript
// eslint.config.js
export default {
  rules: {
    "no-script-url": "error",
    "react/no-danger": "error",
    "react/no-danger-with-children": "error",
    "jsx-no-target-blank": "error",
  },
};
```

---

## 11. Troubleshooting

### Issue 1: "eslint: command not found"

```bash
# Check if installed
npx eslint --version

# Install locally
npm install --save-dev eslint

# Or use npx
npx eslint .
```

### Issue 2: Config file not found

```bash
# Check config file exists
ls -la eslint.config.* .eslintrc.*

# Create config
npx eslint --init

# Specify config explicitly
npx eslint --config ./eslint.config.js .
```

### Issue 3: Rules not being applied

```javascript
// Check file patterns in config
export default [
  {
    files: ["**/*.{js,ts}"],  // Ensure your files match
    rules: {
      "no-console": "error",
    },
  },
];
```

### Issue 4: TypeScript parser errors

```bash
# Install TypeScript parser
npm install --save-dev typescript-eslint @typescript-eslint/parser

# Ensure tsconfig exists
npx tsc --init

# Check parser options
```

```javascript
// eslint.config.js
import tseslint from "typescript-eslint";

export default [
  ...tseslint.configs.recommended,
  {
    languageOptions: {
      parserOptions: {
        project: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
  },
];
```

### Issue 5: "Parsing error: Cannot import ES module"

```javascript
// Use ESM in package.json
{
  "type": "module"
}

// Or use .mjs extension for config
// eslint.config.mjs
```

### Issue 6: Conflicts with Prettier

```bash
# Install prettier config
npm install --save-dev eslint-config-prettier eslint-plugin-prettier

# Add to config
```

```javascript
import prettier from "eslint-config-prettier";

export default [
  // Prettier must be last to override other formatting rules
  prettier,
];
```

### Issue 7: ESLint is slow

```bash
# Enable caching
npx eslint . --cache

# Cache location is .eslintcache by default
# Or specify custom location
npx eslint . --cache --cache-location .tmp/.eslintcache

# Limit files
npx eslint src/

# Parallel processing (v9+)
npx eslint . --parallel
```

### Issue 8: "No files matching the pattern"

```bash
# Check file extensions
npx eslint --ext .js,.ts,.jsx,.tsx .

# Or in config
{
  files: ["**/*.{js,jsx,ts,tsx,vue}"],
}
```

### Issue 9: Rules conflict

```bash
# Disable conflicting rules
npx eslint . --rule '{"prettier/prettier": "off"}'

# Or in config
{
  rules: {
    "prettier/prettier": "off",
  },
}
```

### Issue 10: "Parsing error: Unexpected token"

```bash
# Check parser version
npm ls eslint @typescript-eslint/parser

# Update parser
npm install --save-dev @typescript-eslint/parser@latest

# Check ecmaVersion
{
  languageOptions: {
    ecmaVersion: "latest",
    sourceType: "module",
  },
}
```

### Issue 11: Git hooks not running

```bash
# Install husky
npm install --save-dev husky
npx husky init

# Add lint hook
echo "npx eslint --staged" > .husky/pre-commit

# Or with lint-staged
npm install --save-dev lint-staged
```

```json
// package.json
{
  "lint-staged": {
    "*.{js,ts,jsx,tsx}": ["eslint --fix", "prettier --write"]
  }
}
```

### Issue 12: ESLint ignores not working

```javascript
// Use .eslintignore (legacy) or ignores in config (flat config)
// eslint.config.js
export default [
  {
    ignores: [
      "dist/**",
      "node_modules/**",
      "build/**",
      "*.min.js",
      "coverage/**",
    ],
  },
];
```

### Issue 13: Plugin not found

```bash
# Install the plugin
npm install --save-dev eslint-plugin-react

# Check package name (eslint-plugin-xxx)
npm ls eslint-plugin-react

# Use correct name in config (without "eslint-plugin-" prefix)
{
  plugins: {
    react,  // not "eslint-plugin-react"
  },
}
```

### Issue 14: "Cannot find module" in config

```javascript
// Ensure import is correct
import js from "@eslint/js";
// not: import js from "eslint";

// Check node_modules
npm ls @eslint/js
```

### Issue 15: Exit code 1 despite no errors

```bash
# Check max-warnings
npx eslint . --max-warnings 0  # Fails on any warning

# Or
npx eslint . --max-warnings -1  # No limit

# Check for suggestions (not errors)
npx eslint . --format json | jq '[.[] | select(.severity == 2)] | length'
```

### Issue 16: ESLint ignores files it should lint

```javascript
// Check ignores are not too broad
{
  ignores: [
    "dist/**",      // This ignores all files in dist/
    // not: "dist"   // This ignores only the dist directory itself
  ],
}
```

### Issue 17: "Definition for rule 'xxx' was not found"

```bash
# Plugin may not be installed
npm install --save-dev eslint-plugin-xxx

# Or rule may have been removed
# Check plugin documentation
```

### Issue 18: ESLint crashes on large codebase

```bash
# Increase Node.js memory
NODE_OPTIONS="--max-old-space-size=8192" npx eslint .

# Or lint in smaller chunks
npx eslint src/services/
npx eslint src/components/
npx eslint src/utils/
```

### Issue 19: "Cannot read properties of undefined"

```javascript
// Check config syntax
// BAD: missing spread
export default [
  tseslint.configs.recommended,  // This is an object, not an array

// GOOD: spread the array
export default [
  ...tseslint.configs.recommended,
];
```

### Issue 20: New rules not available after upgrade

```bash
# Clear cache
rm -rf .eslintcache

# Reinstall plugins
rm -rf node_modules
npm install

# Check for breaking changes
npx eslint --print-config src/app.js
```

---

## 12. Tips & Best Practices

### Tip 1: Start with Recommended Configs

```javascript
// eslint.config.js
import js from "@eslint/js";
import tseslint from "typescript-eslint";

export default [
  js.configs.recommended,
  ...tseslint.configs.recommended,
  // Add custom rules on top
];
```

### Tip 2: Use --max-warnings for Gradual Adoption

```bash
# Start with many warnings allowed, reduce over time
npx eslint . --max-warnings 100

# When ready, enforce zero warnings
npx eslint . --max-warnings 0
```

### Tip 3: Cache Linting Results

```bash
# Dramatically faster on subsequent runs
npx eslint . --cache

# Cache location: .eslintcache (default)
```

### Tip 4: Use Editor Integration

Configure ESLint to auto-fix on save in your editor:

```json
// VS Code
{
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": "explicit"
  }
}
```

### Tip 5: Fix Warnings, Not Just Errors

```bash
# Show warnings as errors for stricter enforcement
npx eslint . --max-warnings 0

# Or configure in config
{
  rules: {
    "no-console": "error",  // Was "warn"
  },
}
```

### Tip 6: Use Suggestion-Based Rules

Many rules have suggestions that help learn:

```javascript
{
  rules: {
    "prefer-const": "error",           // Auto-fix available
    "no-var": "error",                 // Auto-fix available
    "eqeqeq": ["error", "always"],    // Has suggestions
  },
}
```

### Tip 7: Create Rule Presets for Your Team

```javascript
// eslint-config-contoso/index.js
export default {
  rules: {
    "no-console": "warn",
    "no-eval": "error",
    "eqeqeq": ["error", "always"],
    "@typescript-eslint/no-unused-vars": "error",
  },
};
```

### Tip 8: Use Per-Directory Overrides

```javascript
// eslint.config.js
export default [
  // Base config
  js.configs.recommended,

  // Stricter for source code
  {
    files: ["src/**"],
    rules: {
      "no-console": "error",
    },
  },

  // Relaxed for tests
  {
    files: ["**/*.test.*", "**/__tests__/**"],
    rules: {
      "no-console": "off",
      "@typescript-eslint/no-explicit-any": "off",
    },
  },

  // Relaxed for config files
  {
    files: ["*.config.*"],
    rules: {
      "no-console": "off",
    },
  },
];
```

### Tip 9: Use Prettier for Formatting, ESLint for Logic

```bash
# Install prettier
npm install --save-dev prettier eslint-config-prettier

# Prettier handles formatting
# ESLint handles code quality
```

### Tip 10: Enable TypeScript Strict Mode with ESLint

```javascript
// eslint.config.js
import tseslint from "typescript-eslint";

export default [
  ...tseslint.configs.recommended,
  {
    rules: {
      "@typescript-eslint/no-explicit-any": "error",
      "@typescript-eslint/no-unsafe-assignment": "error",
      "@typescript-eslint/no-unsafe-member-access": "error",
      "@typescript-eslint/no-unsafe-call": "error",
      "@typescript-eslint/no-unsafe-return": "error",
      "@typescript-eslint/strict-boolean-expressions": "error",
    },
  },
];
```

### Tip 11: Use ESLint in Code Review

```yaml
# GitHub Actions comment on PR
- name: Lint and comment
  uses: eslint/action@v3
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
```

### Tip 12: Auto-Fix in CI for PRs

```yaml
# Auto-fix and commit back to PR
- name: Auto-fix
  run: |
    npx eslint . --fix
    git diff --quiet || git commit -am "fix: auto-fix linting issues"
    git push
```

### Tip 13: Use `--debug` for Troubleshooting

```bash
# See detailed ESLint internals
npx eslint . --debug

# Shows parser decisions, rule loading, etc.
```

### Tip 14: Check Config Resolution

```bash
# See effective config for a file
npx eslint --print-config src/app.js

# Compare configs between files
npx eslint --print-config src/app.js > config1.json
npx eslint --print-config src/utils.js > config2.json
diff config1.json config2.json
```

### Tip 15: Use `.eslintignore` for Global Exclusions

```bash
# .eslintignore (legacy format)
dist/
build/
node_modules/
coverage/
*.min.js
```

### Tip 16: Measure Linting Performance

```bash
# Time linting
time npx eslint .

# Profile with Node.js
node --prof node_modules/.bin/eslint .
node --prof-process isolate-*.log > processed.txt
```

### Tip 17: Use `no-multiple-empty-lines` for Code Hygiene

```javascript
{
  rules: {
    "no-multiple-empty-lines": ["error", { max: 1, maxEOF: 0 }],
  },
}
```

### Tip 18: Enforce Import Ordering

```javascript
import importPlugin from "eslint-plugin-import";

{
  plugins: {
    import: importPlugin,
  },
  rules: {
    "import/order": ["error", {
      groups: ["builtin", "external", "internal", "parent", "sibling", "index"],
      "newlines-between": "always",
      alphabetize: { order: "asc", caseInsensitive: true },
    }],
    "import/no-duplicates": "error",
  },
}
```

### Tip 19: Use `consistent-return` for Clearer Functions

```javascript
{
  rules: {
    "consistent-return": "error",
  },
}
```

### Tip 20: Enforce Naming Conventions

```javascript
{
  rules: {
    "camelcase": ["error", {
      properties: "always",
      ignoreDestructuring: true,
      ignoreImports: true,
    }],
    "@typescript-eslint/naming-convention": [
      "error",
      {
        selector: "variable",
        format: ["camelCase", "UPPER_CASE", "PascalCase"],
      },
      {
        selector: "function",
        format: ["camelCase", "PascalCase"],
      },
      {
        selector: "typeLike",
        format: ["PascalCase"],
      },
    ],
  },
}
```

---

## 13. Command Reference

### Basic Usage

```
eslint [options] [file ... | dir ...]

Options:
  -c, --config path::String        Path to configuration file
  -e, --ext [String]               Specify file extensions to lint
  --resolve-plugins-relative-to path::String  Specify directory for plugin resolution
  --rule Object                    Define a configuration rule
  --plugin [String]                Specify plugins
  --ignore-path path::String       Specify path to ignore file
  --ignore-pattern [String]        Add a pattern to ignore
  --no-ignore                      Disable ignore patterns
  --max-warnings Number            Max warnings before error
  --no-error-on-unmatched-pattern  Disable errors on unmatched patterns
  --format String                  Specify output format (stylish, json, sarif, etc.)
  --output-file path::String       Specify output file
  --color                          Force enable/disable color
  --no-color                       Disable color
  --quiet                          Report errors only
  --max-depth Number               Max call stack depth
  --max-statements Number          Max statements per function
  --debug                          Enable debugging
  --help                           Show help
  --version                        Show version
```

### Lint Modes

```bash
# Lint all files
npx eslint .

# Lint specific files
npx eslint src/app.js src/utils.js

# Lint with specific extensions
npx eslint --ext .js,.ts,.jsx,.tsx .

# Lint from stdin
echo "const x = 1" | npx eslint --stdin --stdin-filename stdin.js
```

### Output Formats

```bash
# Stylish (default)
npx eslint . --format stylish

# JSON
npx eslint . --format json

# JSON with one-line per file
npx eslint . --format json

# SARIF
npx eslint . --format sarif

# JUnit XML
npx eslint . --format junit

# Tap
npx eslint . --format tap

# HTML report
npx eslint . --format html --output-file report.html
```

### Fixing Issues

```bash
# Auto-fix
npx eslint . --fix

# Dry run (show what would be fixed)
npx eslint . --fix-dry-run --format json

# Fix specific rules
npx eslint . --fix --rule '{"semi": "error"}'
```

### Caching

```bash
# Enable caching
npx eslint . --cache

# Custom cache location
npx eslint . --cache --cache-location .tmp/.eslintcache

# Cache strategy
npx eslint . --cache --cache-strategy metadata
```

### Debugging

```bash
# Verbose output
npx eslint . --debug

# Print config for a file
npx eslint --print-config src/app.js

# Show which files would be linted
npx eslint --debug . 2>&1 | grep "Linting"
```

### Common Aliases

```json
// package.json
{
  "scripts": {
    "lint": "eslint .",
    "lint:fix": "eslint . --fix",
    "lint:check": "eslint . --max-warnings 0",
    "lint:report": "eslint . --format json --output-file eslint-report.json",
    "lint:html": "eslint . --format html --output-file eslint-report.html"
  }
}
```

---

## 14. Configuration Reference

### Complete Flat Config

```javascript
// eslint.config.js — Complete Reference
import js from "@eslint/js";
import tseslint from "typescript-eslint";
import react from "eslint-plugin-react";
import reactHooks from "eslint-plugin-react-hooks";
import reactRefresh from "eslint-plugin-react-refresh";
import importPlugin from "eslint-plugin-import";
import security from "eslint-plugin-security";
import prettier from "eslint-config-prettier";
import prettierPlugin from "eslint-plugin-prettier";
import jsxA11y from "eslint-plugin-jsx-a11y";

export default [
  // =========================================================================
  // Global Ignores
  // =========================================================================
  {
    ignores: [
      "dist/**",
      "node_modules/**",
      "build/**",
      "coverage/**",
      "*.min.js",
      "*.min.css",
      "*.map",
      "public/**/*.js",
    ],
  },

  // =========================================================================
  // Base Rules
  // =========================================================================
  js.configs.recommended,

  // =========================================================================
  // TypeScript Rules
  // =========================================================================
  ...tseslint.configs.recommended,

  // =========================================================================
  // Main Configuration
  // =========================================================================
  {
    files: ["**/*.{js,jsx,ts,tsx}"],
    plugins: {
      react,
      "react-hooks": reactHooks,
      "react-refresh": reactRefresh,
      import: importPlugin,
      security,
      "jsx-a11y": jsxA11y,
      prettier: prettierPlugin,
    },

    // Language Options
    languageOptions: {
      ecmaVersion: "latest",
      sourceType: "module",
      parser: tseslint.parser,
      parserOptions: {
        ecmaFeatures: {
          jsx: true,
        },
        project: true,
        tsconfigRootDir: import.meta.dirname,
      },
      globals: {
        window: "readonly",
        document: "readonly",
        navigator: "readonly",
        console: "readonly",
        process: "readonly",
        __dirname: "readonly",
        __filename: "readonly",
        module: "readonly",
        require: "readonly",
        exports: "readonly",
      },
    },

    // Settings
    settings: {
      react: {
        version: "detect",
      },
      "import/resolver": {
        typescript: true,
        node: true,
      },
    },

    // Rules
    rules: {
      // =========================================================================
      // Possible Errors
      // =========================================================================
      "no-console": "warn",
      "no-debugger": "error",
      "no-alert": "warn",
      "no-await-in-loop": "warn",
      "no-template-curly-in-string": "warn",
      "no-unreachable-loop": "error",
      "no-promise-executor-return": "error",

      // =========================================================================
      // Best Practices
      // =========================================================================
      "eqeqeq": ["error", "always"],
      "no-eval": "error",
      "no-implied-eval": "error",
      "no-new-func": "error",
      "no-throw-literal": "error",
      "no-return-await": "warn",
      "no-sequences": "error",
      "no-self-compare": "error",
      "no-unused-expressions": "error",
      "prefer-promise-reject-errors": "error",
      "curly": ["error", "all"],
      "dot-notation": "error",
      "guard-for-in": "warn",
      "no-caller": "error",
      "no-extend-native": "error",
      "no-extra-bind": "error",
      "no-loop-func": "error",
      "no-multi-spaces": "error",
      "no-new-wrappers": "error",
      "no-param-reassign": "error",
      "no-proto": "error",
      "no-shadow": "off",
      "radix": "error",

      // =========================================================================
      // Variables
      // =========================================================================
      "no-unused-vars": "off",
      "no-use-before-define": "off",
      "no-undef": "error",

      // =========================================================================
      // TypeScript
      // =========================================================================
      "@typescript-eslint/no-unused-vars": ["error", {
        argsIgnorePattern: "^_",
        varsIgnorePattern: "^_",
        caughtErrorsIgnorePattern: "^_",
      }],
      "@typescript-eslint/no-explicit-any": "warn",
      "@typescript-eslint/no-non-null-assertion": "warn",
      "@typescript-eslint/consistent-type-imports": ["error", {
        prefer: "type-imports",
      }],
      "@typescript-eslint/no-floating-promises": "error",
      "@typescript-eslint/no-misused-promises": "error",
      "@typescript-eslint/strict-boolean-expressions": "off",

      // =========================================================================
      // Stylistic
      // =========================================================================
      "semi": ["error", "always"],
      "quotes": ["error", "double", { avoidEscape: true }],
      "indent": ["error", 2],
      "no-trailing-spaces": "error",
      "eol-last": "error",
      "comma-dangle": ["error", "always-multiline"],
      "no-multiple-empty-lines": ["error", { max: 1, maxEOF: 0 }],
      "object-curly-spacing": ["error", "always"],
      "array-bracket-spacing": ["error", "never"],
      "no-whitespace-before-property": "error",
      "keyword-spacing": "error",
      "space-before-blocks": "error",
      "space-before-function-paren": ["error", {
        anonymous: "always",
        named: "never",
        asyncArrow: "always",
      }],
      "space-infix-ops": "error",
      "space-unary-ops": "error",
      "spaced-comment": ["error", "always", {
        markers: ["=", "!"],
        exceptions: ["-", "+", "*"],
      }],
      "arrow-spacing": "error",
      "template-curly-spacing": "error",
      "no-mixed-spaces-and-tabs": "error",
      "no-tabs": "error",
      "linebreak-style": ["error", "unix"],
      "max-len": ["warn", {
        code: 120,
        ignoreUrls: true,
        ignoreStrings: true,
        ignoreTemplateLiterals: true,
        ignoreRegExpLiterals: true,
      }],

      // =========================================================================
      // React
      // =========================================================================
      "react/jsx-uses-react": "error",
      "react/jsx-uses-vars": "error",
      "react/jsx-key": "error",
      "react/jsx-no-duplicate-props": "error",
      "react/jsx-no-undef": "error",
      "react/no-direct-mutation-state": "error",
      "react/no-unknown-property": "error",
      "react/prop-types": "off",
      "react/react-in-jsx-scope": "off",
      "react/self-closing-comp": "warn",
      "react/jsx-boolean-value": ["warn", "never"],
      "react/jsx-curly-brace-presence": ["warn", { props: "never", children: "never" }],

      // React Hooks
      "react-hooks/rules-of-hooks": "error",
      "react-hooks/exhaustive-deps": "warn",

      // React Refresh
      "react-refresh/only-export-components": "warn",

      // =========================================================================
      // Import
      // =========================================================================
      "import/no-unresolved": "error",
      "import/named": "error",
      "import/default": "error",
      "import/namespace": "error",
      "import/no-duplicates": "error",
      "import/order": ["error", {
        groups: ["builtin", "external", "internal", "parent", "sibling", "index"],
        "newlines-between": "always",
        alphabetize: { order: "asc", caseInsensitive: true },
      }],
      "import/no-cycle": "warn",
      "import/no-self-import": "error",
      "import/no-relative-parent-imports": "off",

      // =========================================================================
      // Security
      // =========================================================================
      "security/detect-object-injection": "warn",
      "security/detect-non-literal-regexp": "warn",
      "security/detect-non-literal-fs-filename": "warn",
      "security/detect-eval-with-expression": "error",
      "security/detect-no-csrf-before-method-override": "error",
      "security/detect-possible-timing-attacks": "warn",
      "security/detect-pseudoRandomBytes": "warn",

      // =========================================================================
      // JSX Accessibility
      // =========================================================================
      "jsx-a11y/alt-text": "error",
      "jsx-a11y/anchor-has-content": "error",
      "jsx-a11y/anchor-is-valid": "error",
      "jsx-a11y/click-events-have-key-events": "warn",
      "jsx-a11y/no-static-element-interactions": "warn",

      // =========================================================================
      // Prettier (must be last)
      // =========================================================================
      "prettier/prettier": "error",
    },
  },

  // =========================================================================
  // TypeScript Files Override
  // =========================================================================
  {
    files: ["**/*.{ts,tsx}"],
    rules: {
      // TypeScript-specific overrides
    },
  },

  // =========================================================================
  // Test Files Override
  // =========================================================================
  {
    files: ["**/*.{test,spec}.{js,jsx,ts,tsx}", "**/__tests__/**", "**/__mocks__/**"],
    rules: {
      "no-console": "off",
      "@typescript-eslint/no-explicit-any": "off",
      "@typescript-eslint/no-non-null-assertion": "off",
      "security/detect-object-injection": "off",
    },
  },

  // =========================================================================
  // Config Files Override
  // =========================================================================
  {
    files: ["*.config.{js,ts,mjs,cjs}", "vite.config.*", "webpack.config.*", "jest.config.*"],
    rules: {
      "no-console": "off",
    },
  },

  // =========================================================================
  // Node.js Files Override
  // =========================================================================
  {
    files: ["**/*.{mjs,cjs}"],
    languageOptions: {
      sourceType: "script",
      globals: {
        __dirname: "readonly",
        __filename: "readonly",
        module: "readonly",
        require: "readonly",
        exports: "writable",
        process: "readonly",
        console: "readonly",
      },
    },
  },

  // =========================================================================
  // Prettier (must be last)
  // =========================================================================
  prettier,
];
```

---

## 15. Real-World Examples (Contoso Pet Store)

### Scenario: Contoso Pet Store — JavaScript/TypeScript Code Quality

Contoso Pet Store is building a modern web application with React and TypeScript. They need to enforce code quality standards across their team.

### Step 1: Set Up ESLint for the Monorepo

```bash
# Root package.json
cd contoso-pet-store

# Install dependencies
npm install --save-dev eslint @eslint/js typescript-eslint \
  eslint-plugin-react eslint-plugin-react-hooks eslint-plugin-react-refresh \
  eslint-plugin-import eslint-plugin-security \
  eslint-config-prettier eslint-plugin-prettier \
  prettier eslint-config-airbnb
```

### Step 2: Create Shared ESLint Config

```javascript
// packages/eslint-config-contoso/index.js
import js from "@eslint/js";
import tseslint from "typescript-eslint";
import react from "eslint-plugin-react";
import reactHooks from "eslint-plugin-react-hooks";
import importPlugin from "eslint-plugin-import";
import security from "eslint-plugin-security";

export default [
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    files: ["**/*.{js,jsx,ts,tsx}"],
    plugins: {
      react,
      "react-hooks": reactHooks,
      import: importPlugin,
      security,
    },
    rules: {
      // Contoso standards
      "no-console": "warn",
      "no-debugger": "error",
      "eqeqeq": ["error", "always"],
      "no-eval": "error",
      "no-implied-eval": "error",
      "semi": ["error", "always"],
      "quotes": ["error", "double", { avoidEscape: true }],
      "indent": ["error", 2],

      // TypeScript
      "@typescript-eslint/no-unused-vars": ["error", {
        argsIgnorePattern: "^_",
      }],
      "@typescript-eslint/no-explicit-any": "warn",
      "@typescript-eslint/consistent-type-imports": ["error", {
        prefer: "type-imports",
      }],

      // React
      "react/jsx-uses-react": "error",
      "react/jsx-uses-vars": "error",
      "react-hooks/rules-of-hooks": "error",
      "react-hooks/exhaustive-deps": "warn",

      // Imports
      "import/order": ["error", {
        groups: ["builtin", "external", "internal", "parent", "sibling", "index"],
        "newlines-between": "always",
      }],
      "import/no-duplicates": "error",

      // Security
      "security/detect-object-injection": "warn",
      "security/detect-eval-with-expression": "error",
    },
    settings: {
      react: {
        version: "detect",
      },
    },
  },
];
```

### Step 3: Configure Each Package

```javascript
// packages/web-app/eslint.config.js
import contoso from "eslint-config-contoso";

export default [
  ...contoso,
  {
    ignores: ["dist/**", "build/**"],
  },
  {
    files: ["**/*.{test,spec}.{ts,tsx}"],
    rules: {
      "no-console": "off",
      "@typescript-eslint/no-explicit-any": "off",
    },
  },
];
```

```javascript
// packages/api-server/eslint.config.js
import contoso from "eslint-config-contoso";

export default [
  ...contoso,
  {
    rules: {
      "no-console": "off",  // Server can use console.log
      "no-process-exit": "error",
    },
  },
];
```

### Step 4: Add Scripts

```json
// Root package.json
{
  "scripts": {
    "lint": "eslint .",
    "lint:fix": "eslint . --fix",
    "lint:check": "eslint . --max-warnings 0",
    "lint:report": "eslint . --format json --output-file eslint-report.json",
    "lint:ci": "eslint . --format sarif --output-file eslint.sarif"
  }
}
```

### Step 5: CI/CD Pipeline

```yaml
# .github/workflows/lint.yml
name: Lint

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  eslint:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 20

      - name: Install dependencies
        run: npm ci

      - name: Run ESLint
        run: npm run lint:check

      - name: Generate SARIF report
        if: always()
        run: npm run lint:ci

      - name: Upload SARIF
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: eslint.sarif
```

### Step 6: Pre-commit Hook

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/pre-commit/mirrors-eslint
    rev: v9.0.0
    hooks:
      - id: eslint
        args: ['--fix', '--max-warnings', '0']
        additional_dependencies:
          - eslint@9.0.0
          - typescript-eslint@8.0.0
          - eslint-plugin-react@7.34.0
          - eslint-plugin-react-hooks@5.0.0
          - eslint-plugin-import@2.29.0
```

### Step 7: VS Code Configuration

```json
// .vscode/settings.json
{
  "eslint.validate": [
    "javascript",
    "typescript",
    "typescriptreact",
    "javascriptreact"
  ],
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": "explicit"
  },
  "editor.formatOnSave": false,
  "eslint.rules.customizations": [
    { "rule": "*", "severity": "warn" }
  ]
}

// .vscode/extensions.json
{
  "recommendations": [
    "dbaeumer.vscode-eslint",
    "esbenp.prettier-vscode"
  ]
}
```

### Step 8: Example Components

**ProductCard.tsx (Before linting):**
```tsx
import React from 'react';
import { Product } from '../types';

interface Props {
  product: Product;
}

export function ProductCard({product}: Props) {
  var name = product.name
  var price = product.price
  if (product.onSale == true) {
    price = price * 0.9
  }

  return (
    <div>
      <h2>{name}</h2>
      <p>${price}</p>
      <button onClick={() => console.log("clicked")}>Add to Cart</button>
    </div>
  )
}
```

**ProductCard.tsx (After linting):**
```tsx
import type { Product } from "../types";

interface Props {
  product: Product;
}

export function ProductCard({ product }: Props): JSX.Element {
  const name = product.name;
  let price = product.price;

  if (product.onSale === true) {
    price = price * 0.9;
  }

  return (
    <div>
      <h2>{name}</h2>
      <p>${price}</p>
      <button onClick={() => {
        // TODO: Implement add to cart
        console.warn("Add to cart not implemented");
      }}>
        Add to Cart
      </button>
    </div>
  );
}
```

### Step 9: Custom ESLint Rule for Contoso

```javascript
// eslint-plugin-contoso/rules/no-hardcoded-urls.js
export default {
  meta: {
    type: "problem",
    docs: {
      description: "Disallow hardcoded URLs - use environment variables",
    },
    fixable: "code",
    schema: [],
    messages: {
      hardcoded:
        "Hardcoded URL '{{ url }}' found. Use environment variable instead.",
    },
  },

  create(context) {
    return {
      Literal(node) {
        if (typeof node.value === "string" && /^https?:\/\//.test(node.value)) {
          context.report({
            node,
            messageId: "hardcoded",
            data: { url: node.value },
            suggest: [
              {
                desc: "Replace with environment variable",
                fix(fixer) {
                  return fixer.replaceText(node, `process.env.API_URL`);
                },
              },
            ],
          });
        }
      },
    };
  },
};
```

### Step 10: Compliance Report

```bash
#!/bin/bash
# generate-eslint-report.sh

echo "=== Contoso Pet Store ESLint Report ==="
echo "Date: $(date)"
echo ""

# Run ESLint and capture results
npx eslint . --format json --output-file /tmp/eslint-results.json

# Generate summary
TOTAL=$(cat /tmp/eslint-results.json | jq 'length')
ERRORS=$(cat /tmp/eslint-results.json | jq '[.[] | .errorCount] | add')
WARNINGS=$(cat /tmp/eslint-results.json | jq '[.[] | .warningCount] | add')
FIXABLE=$(cat /tmp/eslint-results.json | jq '[.[] | .fixableErrorCount + .fixableWarningCount] | add')

echo "Files scanned: $TOTAL"
echo "Errors: $ERRORS"
echo "Warnings: $WARNINGS"
echo "Auto-fixable: $FIXABLE"
echo ""

# Top issues
echo "=== Top 10 Issues ==="
cat /tmp/eslint-results.json | \
  jq -r '.[].messages[].ruleId' | \
  grep -v null | \
  sort | uniq -c | sort -rn | head -10

# Generate HTML report
npx eslint . --format html --output-file eslint-report.html
echo ""
echo "HTML report: eslint-report.html"
echo "JSON report: /tmp/eslint-results.json"
```

---

## 16. Further Reading

### Official Resources

- [ESLint Documentation](https://eslint.org/docs/)
- [ESLint Rules](https://eslint.org/docs/rules/)
- [TypeScript ESLint](https://typescript-eslint.io/)
- [ESLint Blog](https://eslint.org/blog/)
- [ESLint Playground](https://eslint.org/play/)

### Related Tools

- [Prettier](https://prettier.io/) — Code formatter
- [Biome](https://biomejs.dev/) — Alternative linter/formatter
- [Stylelint](https://stylelint.io/) — CSS linter
- [Markdownlint](https://github.com/DavidAnson/markdownlint) — Markdown linter
- [Commitlint](https://commitlint.js.org/) — Commit message linter

### Plugins Worth Exploring

| Plugin | Description |
|--------|-------------|
| `eslint-plugin-unicorn` | Various ESLint rules |
| `eslint-plugin-sonarjs` | Rules from SonarQube |
| `eslint-plugin-promise` | Promise best practices |
| `eslint-plugin-fp` | Functional programming |
| `eslint-plugin-lodash` | Lodash best practices |
| `eslint-plugin-testing-library` | Testing Library rules |
| `eslint-plugin-jest` | Jest rules |
| `eslint-plugin-cypress` | Cypress rules |
| `eslint-plugin-react-native` | React Native rules |
| `eslint-plugin-tailwindcss` | Tailwind CSS class sorting |

### Configuration Generators

- [Airbnb Style Guide](https://github.com/airbnb/javascript)
- [Standard Style](https://standardjs.com/)
- [Google JavaScript Style Guide](https://google.github.io/styleguide/jsguide.html)
- [Shopify Style Guide](https://github.com/Shopify/javascript)

### Books

- "ESLint: Pluggable JavaScript Linter" by Nicholas C. Zakas
- "Professional JavaScript for Web Developers" by Matt Frisbie

### Community

- [ESLint GitHub](https://github.com/eslint/eslint)
- [ESLint Discord](https://eslint.org/chat/)
- [Stack Overflow: eslint tag](https://stackoverflow.com/questions/tagged/eslint)

### Learning Resources

- [ESLint Getting Started](https://eslint.org/docs/getting-started)
- [TypeScript ESLint Getting Started](https://typescript-eslint.io/getting-started)
- [ESLint Configuration Migration Guide](https://eslint.org/docs/latest/use/configure/migration-guide)

---

*Last updated: 2026-09-03*
*ESLint version: v9.x*
