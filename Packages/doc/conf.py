# imports
from subprocess import Popen, PIPE

# functions
def get_version():
    """
    Returns project version as derived by git.
    """

    branchString = Popen('git rev-parse --abbrev-ref HEAD', stdout = PIPE, shell = True).stdout.read().rstrip()
    revString    = Popen('git describe --always --tags',    stdout = PIPE, shell = True).stdout.read().rstrip()

    return "({branch}) {version}".format(branch=branchString, version=revString)

# sphinx config
extensions = ['sphinx.ext.imgmath', 'sphinx.ext.todo', 'breathe', 'sphinxcontrib.fulltoc', 'sphinx.ext.graphviz']
master_doc = "index"
project= "MIES Igor"

exclude_patterns = [ 'releasenotes_template.rst']

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
highlight_language = "igor"
pygments_style     = "igor"

# breathe
breathe_projects            = { "MIES": "xml" }
breathe_default_project     = "MIES"
breathe_domain_by_extension = { "ipf" : "cpp" }
breathe_default_members     = ('members', 'undoc-members')

# dot
graphviz_output_format = 'svg'
