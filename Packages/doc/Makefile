# Minimal makefile for Sphinx documentation
#

# You can set these variables from the command line.
SPHINXOPTS    = --keep-going -a -P
SPHINXBUILD   = sphinx-build
SPHINXPROJ    = MIES
SOURCEDIR     = .
BUILDDIR      = .

# Put it first so that "make" without argument is like "make help".
help:
	@$(SPHINXBUILD) -M help "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

.PHONY: Makefile autobuild

autobuild:
	sphinx-autobuild -b html --ignore "*~" --ignore ".git" --ignore "*T0" --ignore "*.un~" --open-browser "$(SOURCEDIR)" "$(BUILDDIR)/html" $(O)

# Catch-all target: route all unknown targets to Sphinx using the new
# "make mode" option.  $(O) is meant as a shortcut for $(SPHINXOPTS).
%: Makefile
	@$(SPHINXBUILD) -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)
