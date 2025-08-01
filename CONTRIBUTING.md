# Contributing to Moventum AccountView Extension

Thank you for your interest in contributing to the Moventum AccountView extension for MoneyMoney!

## How to Contribute

### Reporting Issues

Before creating an issue, please check if it already exists. When reporting bugs:

1. Use a clear and descriptive title
2. Describe the exact steps to reproduce the problem
3. Include your MoneyMoney version and macOS version
4. Include any error messages or log output
5. Describe what you expected to happen vs. what actually happened

### Suggesting Features

Feature requests are welcome! Please:

1. Check if the feature already exists or has been requested
2. Explain the use case and why it would be valuable
3. Consider if it fits within the scope of this extension

### Code Contributions

#### Development Setup

1. Fork this repository
2. Clone your fork locally
3. Copy `moventum.lua` to MoneyMoney's Extensions folder for testing
4. Make your changes
5. Test thoroughly with MoneyMoney

#### Code Style

- Follow existing Lua coding conventions
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions focused and single-purpose
- Maintain consistent indentation (2 spaces)

#### Testing

- Test with active Moventum AccountView accounts
- Verify all three account types work correctly
- Test error handling scenarios
- Ensure logging works properly

#### Pull Request Process

1. Create a feature branch from `main`
2. Make your changes with clear commit messages
3. Update documentation if needed
4. Test your changes thoroughly
5. Submit a pull request with:
   - Clear title and description
   - Reference any related issues
   - Description of changes made
   - Testing performed

### MoneyMoney Extension Guidelines

This extension must comply with MoneyMoney's extension requirements:

- No external dependencies
- Secure credential handling
- Proper error handling
- Clean, readable code
- No data collection or third-party communication

### Security Considerations

- Never log or store user credentials
- Use HTTPS for all web requests
- Validate all input data
- Handle sensitive data appropriately
- Report security issues privately to maintainers

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help newcomers learn and contribute
- Maintain a professional tone in all communications

## Questions?

If you have questions about contributing, feel free to:

- Open an issue for general questions
- Contact maintainers for sensitive matters
- Check existing issues and documentation first

Thank you for helping improve this extension!