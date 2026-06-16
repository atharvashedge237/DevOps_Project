# Contributing Guide

Thank you for considering contributing to the MLOps Pipeline project!

## How to Contribute

### 1. Fork and Clone
```bash
git clone https://github.com/yourusername/mlops-pipeline.git
cd mlops-pipeline
```

### 2. Create Feature Branch
```bash
git checkout -b feature/your-feature-name
```

### 3. Make Changes
- Follow Python PEP 8 style guide
- Add tests for new features
- Update documentation
- Keep commits atomic and descriptive

### 4. Test Locally
```bash
# Run tests
cd app && pytest test_main.py -v && cd ..

# Validate Helm chart
helm lint kubernetes/helm-chart

# Validate Terraform
cd terraform && terraform validate && cd ..
```

### 5. Commit and Push
```bash
git commit -m "feat: add feature description"
git push origin feature/your-feature-name
```

### 6. Create Pull Request
- Describe changes clearly
- Reference any related issues
- Include screenshots if applicable

## Code Style

### Python
- Use PEP 8 formatting
- Type hints required
- Docstrings for all functions
- Black formatter: `black app/`

### YAML/Kubernetes
- 2-space indentation
- Descriptive resource names
- Include labels and annotations
- Document custom values

### Terraform
- 2-space indentation
- Use variables for configuration
- Include descriptions
- Follow Terraform style conventions

## Testing Requirements

- All code must have unit tests
- Maintain >80% code coverage
- Add integration tests for new features
- Test locally before submitting PR

## Documentation

- Update README.md for user-facing changes
- Add comments for complex logic
- Include examples for new features
- Update QUICKSTART.md if needed

## Code Review Process

1. Automated tests must pass
2. Code review by maintainers
3. Address feedback
4. Merge when approved

## Reporting Issues

Include:
- Clear description of issue
- Steps to reproduce
- Expected vs actual behavior
- Environment details
- Screenshots if applicable

## Questions?

Create a GitHub Discussion or issue.

Thanks for contributing! 🎉
