def shell_tool_test(name, script=[], scriptfile='', tools={}, data=[],
                    args=[], size='small', tags=[]):
  """A macro to invoke a test script with access to specified tools.

  Each tool named by the tools attribute is available in the script via a
  variable named by the corresponding key. For example, if tools contains

     "A": "//foo/bar:baz"

  then $A refers to the location of //foo/bar:baz in the script. Each element
  of script becomes a single line of the resulting test.

  Exactly one of "script" or "scriptfile" must be set. If "script" is set, it
  is used as an inline script; otherwise "scriptfile" must be a file target
  containing the script to be included.

  Any targets specified in "data" are included as data dependencies for the
  resulting sh_test rule without further interpretation.
  """
  if (len(script) == 0) == (scriptfile == ''):
    fail('You must set exactly one of "script" or "scriptfile"')

  bases = sorted(tools.keys())
  lines = ["set -e", 'cat >$@ <<"EOF"'] + [
      'readonly %s="$${%d:?missing %s tool}"' % (base, i+1, base)
      for i, base in enumerate(bases)
  ] + ["shift %d" % len(bases)] + script + ["EOF"]
  if scriptfile:
    lines += [
        "# --- end generated section ---",
        'cat >>$@ "$(location %s)"' % scriptfile,
    ]

  genscript = name + "_test_script"
  native.genrule(
      name = genscript,
      outs = [genscript+".sh"],
      srcs = [scriptfile] if scriptfile else [],
      testonly = True,
      cmd = "\n".join(lines),
      tags = tags,
  )
  test_args = ["$(location %s)" % tools[base] for base in bases]
  native.sh_test(
      name = name,
      data = sorted(tools.values()) + data,
      srcs = [genscript],
      args = test_args + args,
      size = size,
      tags = tags,
  )
