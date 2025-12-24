# Contributing to APEX Insights Demos

This repository hosts the live demos and code samples for the [APEX Insights Blog](https://insightsapex.hashnode.dev).

## 🛡️ Workflow

- **Protected Branch**: `main`. Direct pushes are blocked.
- **Pull Requests**: Required for any change.

### How to Add a New Demo

1. Create a new folder in the root with the format `YYYY-MM-DD-topic-name`.
2. Include all necessary SQL scripts and APEX application exports (`fXXX.sql`).
3. Add a `README.md` inside that folder complying with the blog post structure.
4. Open a Pull Request targeting `main`.

## 🤝 Standards

- **Clean Code**: Ensure SQL scripts are idempotent (can be run multiple times without error) if possible.
- **No Credentials**: NEVER commit passwords, wallet files, or sensitive data.

Thank you!
