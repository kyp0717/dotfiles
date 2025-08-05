# Dotfile Context Engineering - Rules for Dotfile development and deployment 

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Goal
- Build a suite of configurations for various tools and commands for use as a development environment.
- These tools are:
  - Neovim (via neovim-rust is the desired configuration at the moment)
  - Nushell
  - Wezterm
  - Zed
  - Starship as the command line prompt
- These tools are defined as a set of configurations each with it owns folder
- Use linux command stow to deploy these scripts to the `~/.config` directory within ubuntu

## Project Awareness & Context
- Project level contexts are located in `prps/` folder.   
- **Always read `/prps/project.md`** at the start of a new conversation to understand the project's architecture, goals, style, and constraints.
- **Check `prps/tasks.md`** before starting a new task. If the task isn’t listed, add it with a brief description and today's date.
- **Use consistent naming conventions, file structure, and architecture patterns** as described in `prps/PLANNING.md`.

## Code Structure & Modularity
- **Never create a file longer than 500 lines of code.** If a file approaches this limit, refactor by splitting it into modules or helper files.
- **Organize code into clearly separated modules**, grouped by feature or responsibility.
- Never hardcode sensitive information - Always use .env files for API keys and configuration

## Testing & Reliability
- **After updating any logic**, check whether existing unit tests need to be updated. If so, do it.
- **Tests should live in a `/tests` folder** mirroring the main app structure.
  - Include at least:
    - 1 test for expected use
    - 1 edge case
    - 1 failure case

## Task Completion
- Use the `tasks.md` file in the `prps/` to track the status of all the tasks that need to be done
- Add new tasks to the tasks.md file 
- **Mark completed tasks in `tasks.md`** immediately after finishing them.
- Add new sub-tasks or TODOs discovered during development to `tasks.md` under a “Discovered During Work” section.

### 📎 Modification Guideline
- When modifying code, always  

### 📎 Style & Conventions
- **To be determine

### 📚 Documentation & Explainability
- **Update `README.md`** when new features are added, dependencies change, or setup steps are modified.
- **Comment non-obvious code** and ensure everything is understandable to a mid-level developer.
- When writing complex logic, **add an inline `# Reason:` comment** explaining the why, not just the what.

### 🧠 AI Behavior Rules
- **Never assume missing context. Ask questions if uncertain.**
- **Never hallucinate libraries or functions** – only use known, verified Python packages.
- **Always confirm file paths and module names** exist before referencing them in code or tests.
- **Never delete or overwrite existing code** unless explicitly instructed to or if part of a task from `task.md`.
