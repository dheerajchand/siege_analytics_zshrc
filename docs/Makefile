# Minimal makefile for Sphinx documentation
#

# You can set these variables from the command line, and also
# from the environment for the first two.
SPHINXOPTS    ?=
SPHINXBUILD   ?= sphinx-build
SOURCEDIR     = .
BUILDDIR      = _build

# Put it first so that "make" without argument is like "make help".
help:
	@$(SPHINXBUILD) -M help "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

.PHONY: help Makefile

# Catch-all target: route all unknown targets to Sphinx using the new
# "make mode" option.  $(O) is meant as a shortcut for $(SPHINXOPTS).
%: Makefile
	@$(SPHINXBUILD) -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

# Custom targets for Siege Analytics documentation

# Install dependencies
install:
	pip install -r requirements.txt

# Clean build directory
clean:
	rm -rf $(BUILDDIR)/*

# Build HTML documentation
html: clean
	@echo "Building HTML documentation..."
	@$(SPHINXBUILD) -b html "$(SOURCEDIR)" "$(BUILDDIR)/html" $(SPHINXOPTS) $(O)
	@echo "HTML documentation built in $(BUILDDIR)/html/"

# Build PDF documentation
pdf: clean
	@echo "Building PDF documentation..."
	@$(SPHINXBUILD) -b latex "$(SOURCEDIR)" "$(BUILDDIR)/latex" $(SPHINXOPTS) $(O)
	@echo "Running pdflatex..."
	@cd $(BUILDDIR)/latex && pdflatex -interaction=nonstopmode *.tex
	@cd $(BUILDDIR)/latex && pdflatex -interaction=nonstopmode *.tex
	@echo "PDF documentation built in $(BUILDDIR)/latex/"

# Build EPUB documentation
epub: clean
	@echo "Building EPUB documentation..."
	@$(SPHINXBUILD) -b epub "$(SOURCEDIR)" "$(BUILDDIR)/epub" $(SPHINXOPTS) $(O)
	@echo "EPUB documentation built in $(BUILDDIR)/epub/"

# Serve documentation locally
serve: html
	@echo "Starting local server..."
	@cd $(BUILDDIR)/html && python -m http.server 8000
	@echo "Documentation available at http://localhost:8000"

# Auto-rebuild on changes
watch:
	@echo "Starting auto-rebuild server..."
	@sphinx-autobuild "$(SOURCEDIR)" "$(BUILDDIR)/html" $(SPHINXOPTS) $(O)

# Check for broken links
linkcheck:
	@echo "Checking for broken links..."
	@$(SPHINXBUILD) -b linkcheck "$(SOURCEDIR)" "$(BUILDDIR)/linkcheck" $(SPHINXOPTS) $(O)

# Check spelling
spelling:
	@echo "Checking spelling..."
	@$(SPHINXBUILD) -b spelling "$(SOURCEDIR)" "$(BUILDDIR)/spelling" $(SPHINXOPTS) $(O)

# Lint documentation
lint:
	@echo "Linting documentation..."
	@ruff check .
	@black --check .

# Format documentation
format:
	@echo "Formatting documentation..."
	@black .
	@ruff check --fix .

# Full build with all checks
build: clean html linkcheck
	@echo "Full build completed successfully!"

# Deploy to GitHub Pages
deploy: html
	@echo "Deploying to GitHub Pages..."
	@ghp-import -n -p -f $(BUILDDIR)/html/
	@echo "Deployed to GitHub Pages!"

# Create logo and favicon (placeholder)
assets:
	@echo "Creating placeholder assets..."
	@mkdir -p _static
	@echo "Creating placeholder logo..."
	@convert -size 200x200 xc:'#00FF41' -fill white -pointsize 24 -gravity center -annotate +0+0 'SA' _static/logo.png 2>/dev/null || echo "ImageMagick not available, skipping logo creation"
	@echo "Creating placeholder favicon..."
	@convert -size 32x32 xc:'#00FF41' -fill white -pointsize 8 -gravity center -annotate +0+0 'SA' _static/favicon.ico 2>/dev/null || echo "ImageMagick not available, skipping favicon creation"

# Setup development environment
setup: install assets
	@echo "Setting up development environment..."
	@pre-commit install
	@echo "Development environment ready!"

# All-in-one build
all: setup build
	@echo "Complete documentation build finished!"

# Quick development build
dev: html
	@echo "Quick development build completed!"

# Production build
prod: clean html pdf epub
	@echo "Production build completed with HTML, PDF, and EPUB!"

.PHONY: install clean html pdf epub serve watch linkcheck spelling lint format build deploy assets setup all dev prod
