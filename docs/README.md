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
├── _build/html/                    # Built HTML documentation
├── _static/                        # Static assets (CSS, images)
├── big-data/                       # Big data tools documentation
├── core-systems/                   # Core system documentation
├── development/                    # Development workflows
├── getting-started/                # Installation and setup guides
├── security/                       # Security documentation
├── DIRECTORY_CLEANUP_SAFETY_PLAN.md # 🛡️ Directory safety framework
├── MAIN_README.md                  # 📋 Main project documentation
├── SYSTEM_ARCHITECTURE.md         # 🏗️ System architecture guide
├── conf.py                         # Sphinx configuration
├── index.rst                       # Main documentation index
├── Makefile                        # Build automation
└── requirements.txt                # Python dependencies
```

## 🛡️ **Security Documentation**

### **NEW: Directory Safety Framework**
- **`DIRECTORY_CLEANUP_SAFETY_PLAN.md`** - Comprehensive safety plan for directory operations
  - 7-phase safety strategy with forensic analysis
  - Safe move procedures with automatic rollback
  - Atomic operations and dependency mapping
  - Emergency procedures and system recovery
  - **Production-ready** with hostile testing certification

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
