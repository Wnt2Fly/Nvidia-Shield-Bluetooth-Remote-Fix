# Contributing to shield-bluetooth-fix

First off, thank you for considering contributing to this project! 🎉

## 🤝 How to Contribute

### Reporting Issues

If you're experiencing problems:

1. **Check existing issues** to see if it's already reported
2. **Use the issue template** (if available)
3. **Include details:**
   - Shield model and Android version
   - Output of the diagnostic script
   - Steps to reproduce the issue
   - What you expected vs. what happened

### Suggesting Enhancements

Have an idea to improve the tool? Great!

1. **Check if it's already suggested** in issues
2. **Open an issue** describing:
   - The enhancement you'd like
   - Why it would be useful
   - How it should work

### Code Contributions

#### Getting Started

1. **Fork the repository**
2. **Clone your fork:**
   ```bash
   git clone https://github.com/yourusername/shield-bluetooth-fix.git
   cd shield-bluetooth-fix
   ```
3. **Create a branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

#### Making Changes

1. **Make your changes** in your branch
2. **Test thoroughly** on actual Shield hardware
3. **Update documentation** if needed (README.md)
4. **Follow the existing code style:**
   - Descriptive variable names
   - Comments for complex logic
   - Clear echo/print statements for user feedback

#### Submitting Changes

1. **Commit your changes:**
   ```bash
   git add .
   git commit -m "Add feature: brief description"
   ```
2. **Push to your fork:**
   ```bash
   git push origin feature/your-feature-name
   ```
3. **Open a Pull Request** with:
   - Clear description of what changed
   - Why the change is needed
   - Testing you've done
   - Screenshots (if UI changes)

## 🧪 Testing Guidelines

Before submitting:

- ✅ Test on at least one Shield device
- ✅ Verify the script doesn't break existing functionality
- ✅ Test both success and failure scenarios
- ✅ Ensure error messages are clear and helpful

## 📋 Areas for Contribution

### High Priority
- [ ] GUI wrapper for the scripts (Electron, Python tkinter, etc.)
- [ ] Support for additional Bluetooth devices
- [ ] Automated testing framework
- [ ] Localization (translations)

### Medium Priority
- [ ] Better error recovery mechanisms
- [ ] More detailed Bluetooth diagnostics
- [ ] Shield firmware version compatibility matrix
- [ ] Video tutorials

### Low Priority
- [ ] Alternative installation methods (brew, apt, etc.)
- [ ] Windows installer (.msi)
- [ ] Integration with Shield companion apps

## 💬 Communication

- **Issues:** For bug reports and feature requests
- **Pull Requests:** For code contributions
- **Discussions:** For questions and general discussion

## 📜 Code of Conduct

### Our Pledge

We pledge to make participation in this project a harassment-free experience for everyone.

### Our Standards

**Positive behavior:**
- Being respectful and inclusive
- Accepting constructive criticism gracefully
- Focusing on what's best for the community
- Showing empathy towards others

**Unacceptable behavior:**
- Harassment, trolling, or insulting comments
- Personal or political attacks
- Publishing private information
- Other unprofessional conduct

### Enforcement

Instances of unacceptable behavior may result in:
1. Warning
2. Temporary ban
3. Permanent ban

Project maintainers have the right and responsibility to remove comments, commits, code, issues, and other contributions that don't align with this Code of Conduct.

## 🎓 Development Setup

### Prerequisites

- ADB installed and configured
- Nvidia Shield for testing (or Android TV device)
- Text editor or IDE
- Basic knowledge of shell scripting (bash/batch)

### Project Structure

```
shield-bluetooth-fix/
├── README.md                 # Main documentation
├── Shield_Bluetooth_Fix.bat # Windows script
├── Shield_Bluetooth_Fix.sh  # Linux/Mac script
├── LICENSE                   # MIT License
├── CONTRIBUTING.md          # This file
└── .gitignore               # Git ignore rules
```

## ✅ Pull Request Checklist

Before submitting your PR, verify:

- [ ] Code follows existing style
- [ ] All changes are tested
- [ ] Documentation is updated
- [ ] Commit messages are clear
- [ ] No unnecessary files included
- [ ] .gitignore is respected

## 🏆 Recognition

Contributors will be:
- Listed in the README (if desired)
- Credited in release notes
- Given a shoutout in the project

## 📧 Questions?

Feel free to open an issue with the "question" label if you need help!

---

**Thank you for helping make Shield Bluetooth connections more reliable!** 🚀
