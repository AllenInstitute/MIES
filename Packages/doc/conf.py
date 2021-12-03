# imports
from subprocess import Popen, PIPE

def setup(app):
    app.add_css_file('custom.css')

# functions
def get_version():
    """
    Returns project version as derived by git.
    """

    branchString = Popen('git rev-parse --abbrev-ref HEAD', stdout = PIPE, shell = True).stdout.read().rstrip()
    revString    = Popen('git describe --always --tags --match "Release_*"', stdout = PIPE, shell = True).stdout.read().rstrip()

    return "({branch}) {version}".format(branch=branchString.decode('ascii'), version=revString.decode('ascii'))

# sphinx config
extensions = ['sphinx.ext.mathjax', 'sphinx.ext.todo', 'breathe', \
              'sphinxcontrib.fulltoc', 'sphinxcontrib.images',    \
              'sphinxembeddedvideos.youtube']

master_doc = "index"
project= "MIES Igor"

html_static_path = ['_static']

html_show_sourcelink = False

exclude_patterns = [ 'releasenotes_template.rst', 'IPNWB/specifications']

cpp_id_attributes = [ 'threadsafe' ]

version = get_version()
release = version

# theming
html_theme = "classic"
html_theme_options = {
        "collapsiblesidebar": "true",
        "bodyfont" : "Helvetica, Arial, sans-serif",
        "headfont" : "Helvetica, Arial, sans-serif"
        }

# pygments options
highlight_language = "text"
pygments_style     = "igor"

# breathe
breathe_projects            = { "MIES": "xml" }
breathe_default_project     = "MIES"
breathe_domain_by_extension = { "ipf" : "cpp" }
breathe_default_members     = ('members', 'undoc-members')

images_config = {"override_image_directive": True}
