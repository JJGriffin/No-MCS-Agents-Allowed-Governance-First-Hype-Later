# Contributing Guide

Thank you for contributing to the Agent365 Governance repository!

## Getting Started

1. Clone the repository
2. Review the governance policy in `docs/agent-governance-policy.md`
3. Set up your development environment

## Repository Structure

```
.
├── automation-scripts/      # Automation scripts for Agent365 tasks
│   ├── powershell/         # PowerShell scripts
│   ├── python/             # Python scripts
│   └── shared/             # Shared utilities
├── power-platform-solutions/ # Power Platform solutions
│   ├── managed/            # Managed solution packages
│   ├── unmanaged/          # Unmanaged solution packages
│   └── src/                # Unpacked solution source
├── docs/                   # Governance docs and templates
└── tests/                  # Test scripts and validation
```

## Contributing Automation Scripts

### PowerShell Scripts

1. Place in appropriate subfolder under `automation-scripts/powershell/`
2. Use approved PowerShell verbs (Get, Set, New, Remove, etc.)
3. Include proper error handling and logging
4. Add parameter validation and help documentation
5. Test with `-WhatIf` and `-Verbose` support

**Example header**:
```powershell
<#
.SYNOPSIS
    Brief description of what the script does
.DESCRIPTION
    Detailed description
.PARAMETER ParameterName
    Parameter description
.EXAMPLE
    Example usage
.NOTES
    Author: Your Name
    Date: YYYY-MM-DD
    Version: 1.0
#>
```

### Python Scripts

1. Place in appropriate subfolder under `automation-scripts/python/`
2. Use type hints and docstrings
3. Include proper error handling and logging
4. Add requirements to `requirements.txt` if needed
5. Follow PEP 8 style guidelines

**Example header**:
```python
"""
Script description

Author: Your Name
Date: YYYY-MM-DD
Version: 1.0
"""
```

## Contributing Power Platform Solutions

### Solution Guidelines

1. **Development**:
   - Develop in a dedicated dev environment
   - Use meaningful solution names and versions
   - Document all components

2. **Export**:
   - Export unmanaged solution for development
   - Export managed solution for deployment
   - Unpack to source format for version control

3. **Version Control**:
   - Commit unpacked source to `power-platform-solutions/src/`
   - Include solution documentation
   - Update CHANGELOG.md

4. **Testing**:
   - Test in test environment before committing
   - Document test results
   - Obtain approvals

### Unpacking Solutions

```bash
# Unpack for version control
pac solution unpack --zipfile "unmanaged/MySolution.zip" --folder "src/MySolution"
```

### Required Documentation

Each solution must include:
- `SOLUTION_README.md` - Overview and purpose
- `DEPLOYMENT_GUIDE.md` - How to deploy
- `CONFIGURATION.md` - Environment variables and settings
- `CHANGELOG.md` - Version history

## Pull Request Process

1. **Branch**: Create a feature branch from `main`
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Develop**: Make your changes following guidelines above

3. **Test**: Test thoroughly in dev/test environment

4. **Document**: Update relevant documentation

5. **Commit**: Use clear, descriptive commit messages
   ```bash
   git commit -m "Add: Script to automate agent deployment"
   ```

6. **Push**: Push your branch
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Pull Request**: Create PR with:
   - Clear description of changes
   - Testing performed
   - Any breaking changes
   - Documentation updates

8. **Review**: Address review feedback

9. **Merge**: Once approved, maintainers will merge

## Commit Message Guidelines

Use conventional commits format:

- `Add:` New features or files
- `Update:` Changes to existing functionality
- `Fix:` Bug fixes
- `Docs:` Documentation changes
- `Refactor:` Code refactoring
- `Test:` Adding or updating tests
- `Chore:` Maintenance tasks

## Code Review Checklist

Before submitting PR, verify:

- [ ] Code follows style guidelines
- [ ] Tests pass successfully
- [ ] Documentation is updated
- [ ] No credentials or secrets committed
- [ ] `.gitignore` properly configured
- [ ] Required approvals obtained
- [ ] Governance policy compliance verified

## Security

**Never commit**:
- Passwords or credentials
- API keys or tokens
- Connection strings with secrets
- Personal identifiable information (PII)
- Environment-specific configurations with secrets

Use environment variables, Azure Key Vault, or other secret management solutions.

## Questions?

Open an issue for:
- Questions about contributing
- Clarification on governance policies
- Feature requests
- Bug reports

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.
