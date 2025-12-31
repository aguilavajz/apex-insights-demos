# Contributing Guide

Welcome! We appreciate your interest in contributing. This document specifies the workflow and standards for this repository.

## 🚀 Git Flow & Branching Strategy

We follow a strict **Git Flow** workflow:

1. **`develop` (Default Branch)**: All active development happens here. **Create your branches from `develop`.**
2. **`main` (Release Branch)**: Reserved for production releases at the end of a Sprint.
3. **Feature Branches**:
    * Format: `feature/brief-description` or `fix/issue-description`
    * Source: `develop`
    * Target: Pull Request to `develop`

> **Note:** Do NOT merge directly to `main` unless it is a hotfix.

## 📋 Issue & Labels

* **Templates**: Use the provided [Issue Templates](.github/ISSUE_TEMPLATE/) for Bugs, Features, and Chores.
* **Labels**: We use a `category: name` standard (e.g., `type: bug`, `priority: critical`, `status: blocked`).

## 🤖 AI Guidelines

If you are using GitHub Copilot or other AI tools, please refer to [copilot-instructions.md](.github/copilot-instructions.md) for project-specific context and coding standards.
