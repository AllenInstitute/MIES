# Proof of concept implementation for using doxygen to document Igor Pro procedures
# This awk script serves as input filter for Igor procedures and produces a C++-ish version of the declarations
# Tested with Igor Pro 6.37 and doxygen 1.8.10
#
# Thomas Braun: 10/2015
# Version: 0.26

# Supported Features:
# -Functions
# -Macros
# -File constants
# -Menu items are currently ignored

# TODO
# - don't delete the function/macro subType

BEGIN{
  # allows to bail out for code found outside of functions/macros
  DO_WARN=0
  IGNORECASE=1
  output=""
  warning=""

  menuEndCount    = 0
  insideNamespace = 0
  insideFunction  = 0
  insideStructure = 0
  insideMacro     = 0
  insideMenu      = 0

  namespace=""
}

# Remove whitespace at beginning and end of string
# Return the whitespace in front of the string in the
# global variable frontSpace to be able
# to reconstruct the indentation
function trim(str)
{
  gsub(/[[:space:]]+$/,"",str)

  if(match(str, /^[[:space:]]+/))
  {
    frontSpace = substr(str, 1, RLENGTH)
    str = substr(str, RLENGTH + 1)
  }
  else
    frontSpace = ""

  return str
}

# Split an already trimmed line into words
# Returns the number of words
function splitIntoWords(str, a, numEntries)
{
  return split(str,a,/[[:space:],&*]+/)
}

# Split params into words and prefix each with "__Param__$i"
# where $i is increased for every parameter
# Returns the concatenation of all prefixed parameters
function handleParameter(params, a,  i, iOpt, str, entry)
{
  numParams = splitIntoWords(params, a)
  str=""
  entry=""
  iOpt=numParams
  for(i=1; i <= numParams; i++)
  {
    # convert igor optional parameters to something doxygen understands
    # igor dictates that the optional arguments are the last arguments,
    # meaning no normal argument can follow the optional arguments
    if(gsub(/[\[\]]/,"",a[i]) || i > iOpt)
    {
      iOpt  = i
      entry = a[i] " = defaultValue"
    }
    else
      entry = a[i]

    str = str "__Param__" i " " entry
    if(i < numParams)
     str = str ", "
  }
  return str
}

{
  # split current line into code and comment
  if(match($0,/\/\/.*/))
  {
    code=substr($0,1,RSTART-1)
    comment=substr($0,RSTART,RLENGTH)
  }
  else
  {
    code=$0
    comment=""
  }
  # remove whitespace from front and back
  code=trim(code)

  if(match(code, /^#pragma independentModule\s*=\s*/))
  {
	  namespace = substr(code, RSTART + RLENGTH)
	  code = "namespace " namespace " {"
	  insideNamespace = 1
  }

  # begin of macro definition
  if(!insideFunction && !insideMacro && ( match(code,/^Window/)|| match(code,/^Proc/) || match(code,/^Macro/) ) )
  {
    insideMacro=1
    gsub(/^Window/,"void",code)
    gsub(/^Macro/,"void",code)
    gsub(/^Proc/,"void",code)

    # add opening bracket, this also throws away any function subType
    gsub(/\).*/,"){",code)
  }
  # end of macro definition
  else if(!insideFunction && insideMacro && ( match(code,/^EndMacro$/) || match(code,/^End$/) ) )
  {
    insideMacro=0
    code = "}"
  }
  # begin of function declaration
  else if(!insideFunction && ( match(code,/[[:space:]]function[\/[:space:]]/) || match(code,/^function[\/[:space:]]/)))
  {
    insideFunction=1
    paramsToHandle=0
    # remove whitespace between function and return type flag
    gsub(/function[[:space:]]*\//,"function/",code)

    # different return types
    gsub(/function /,"variable ",code)
    gsub(/function\/df/,"dfr",code)
    gsub(/function\/wave/,"wave",code)
    gsub(/function\/c/,"complex",code)
    gsub(/function\/s/,"string",code)
    gsub(/function\/t/,"string",code) # deprecated definition of string return type
    gsub(/function\/d/,"variable",code)

    # add opening bracket, this also throws away any function subType
    gsub(/\).*/,"){",code)

    # do we have function parameters
    if(match(code,/\(.*[a-z]+.*\)/))
    {
      paramStr = substr(code,RSTART+1,RLENGTH-2)

      paramStrWithTypes = handleParameter(paramStr, params)
      paramsToHandle = numParams
      # print "paramStr __ " paramStr
      # print "paramStrWithTypes __ " paramStrWithTypes
      # print "paramsToHandle __ " paramsToHandle

      code = substr(code,1,RSTART) "" paramStrWithTypes "" substr(code,RSTART+RLENGTH-1)
    }
  }
  else if(insideFunction && paramsToHandle > 0)
  {
   numEntries = splitIntoWords(code,entries)

   # printf("Found %d words in line \"%s\"\n",numEntries,code)
    for(i=2; i <= numEntries; i++)
      for(j=1; j <= numParams; j++)
      {
        variableName = entries[i]
        if( entries[i] == params[j] )
        {
          paramsToHandle--
          # now replace __Param__$i with the real parameter type
          if(entries[1] == "struct" || entries[1] == "funcref")
            paramType = entries[2]
          else
            paramType = tolower(entries[1])

          # add asterisk for call-by-reference parameters
          if(match(code,/\&/))
            paramType = paramType "*"

          output = gensub("__Param__" j " ",paramType " ","g",output)
          # printf("Found parameter type %s at index %d\n",paramType,j)
        }
      }
  }
  # end of function declaration
  else if(insideFunction && match(code,/^end$/))
  {
    insideFunction=0
    code = "}"
  }

  if(insideFunction || insideMacro)
  {
    # invalidate the names of functions behind proc=
    gsub(/\yproc\y=[[:space:]]*/,"&__", code)
    # invalidate the names of functions behind hook(.+)=
    gsub(/\yhook\y(\([^\)]+\))?[[:space:]]*=[[:space:]]*/, "&__", code)
    # comment out FUNCREF lines
    gsub(/^FUNCREF/, "//&", code)
  }

  # structure declaration
  if(!insideFunction && !insideMacro && ( match(code,/[[:space:]]structure[[:space:]]/) || match(code,/^structure[[:space:]]/) )  )
  {
    insideStructure=1
    gsub(/structure/,"struct",code)
    code = code "{"
  }
  else if(insideStructure && match(code,/^FUNCREF/))
  {
    # remove the name of the prototype function
    # in C/C++ we don't use function pointer the igor way
    # so there is little sense in keeping it
    numEntries = splitIntoWords(code, entries)
    code = "funcref " entries[numEntries]
  }
  else if(insideStructure && match(code,/EndStructure/))
  {
    insideStructure=0
    code = "}"
  }

  # translate "#if defined(symbol)" to "#ifdef symbol"
  if(!insideFunction && !insideMacro && !insideMenu && !insideStructure && match(code,/^#if[[:space:]]+defined\(.+\)[[:space:]]*$/))
  {
    gsub(/^#if[[:space:]]+defined\(/,"#ifdef ",code)
    gsub(/)/,"",code)
  }

  # menu definition
  # submenues can be nested in menus. Therefore we have to keep track
  # of the number of expected "End" keywords
  if(!insideFunction && !insideMacro && ( match(code,/\yMenu\y/) || match(code,/\ySubMenu\y/) ))
  {
    menuEndCount++
    insideMenu=1
  }

  if(insideMenu && match(code,/\yEnd[[:space:]]*/))
  {
    menuEndCount--
    if(menuEndCount == 0)
    {
      insideMenu=0
      code = ""
    }
  }

  # global constants
  gsub(/\ystrconstant\y/,"const string",code)
  gsub(/\yconstant\y/,"const variable",code)
  # prevent that doxygen sees elseif as a function call
  gsub(/\yelseif\y/,"else if",code)

  # code outside of function/macro definitions is "translated" into statements
  if(!insideFunction && !insideMacro && !insideMenu && code != "" && substr(code,1,1) != "#")
  {
    if(code != "}" && !insideStructure && DO_WARN)
      warning = warning "\n" "warning " NR ": outside code \"" code "\""

    code = code ";"
  }

  if(!insideMenu)
  {
    output = output frontSpace code comment
  }

  output = output "\n"
}

END{
  print output

  if(insideNamespace)
	  print "} // closing namespace " namespace

  if(DO_WARN)
    print warning
}
