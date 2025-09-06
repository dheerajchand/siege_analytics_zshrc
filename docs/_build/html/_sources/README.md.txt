# 📚 Read the Docs Documentation

This directory contains the professional Sphinx-based documentation for the Enhanced Zsh Configuration System.

## 🚀 Quick Access

### **📖 [View Documentation](_build/html/index.html)**
- **Professional Sphinx Documentation** with Read the Docs theme
- **Interactive Navigation** and search functionality
- **Siege Analytics Branding** with custom styling
- **Comprehensive Guides** for all system components

### **📝 [Wiki Documentation](../wiki/Home.md)**
- **Function References** and detailed guides
- **System Architecture** documentation
- **Bash Compatibility** layer documentation
- **Quick Start** guides and tutorials

## 🏗️ Building Documentation

To build the documentation locally:

```bash
# Install dependencies
pip install -r requirements.txt

# Build HTML documentation
make html

# Serve documentation locally
make serve
```

## 📁 Documentation Structure

```
docs/
├── _build/html/          # Built HTML documentation
├── _static/              # Static assets (CSS, images)
├── big-data/             # Big data tools documentation
├── core-systems/         # Core system documentation
├── development/          # Development workflows
├── getting-started/      # Installation and setup guides
├── conf.py              # Sphinx configuration
├── index.rst            # Main documentation index
├── Makefile             # Build automation
└── requirements.txt     # Python dependencies
```

## 🔗 Integration

This documentation system is integrated with:

- **Wiki System**: Cross-referenced with wiki documentation
- **GitHub Repository**: Automatically synced with main repository
- **Backup System**: Included in automated backups
- **CI/CD**: Can be deployed to GitHub Pages or Read the Docs

## 🎨 Customization

The documentation uses:

- **Read the Docs Theme**: Professional appearance
- **Siege Analytics Branding**: Custom colors and styling
- **Mermaid Diagrams**: Interactive flowcharts and diagrams
- **Cross-References**: Links between documentation sections
- **Search Functionality**: Full-text search across all content

---

**Note**: This documentation is automatically built and updated with the main repository. For the most up-to-date information, always refer to the built HTML documentation in `_build/html/`.
