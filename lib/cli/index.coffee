require('colors')

path         = require 'path'
pkg          = require '../../package.json'
ArgParse     = require('argparse').ArgumentParser
EventEmitter = require('events').EventEmitter

###*
 * @class  CLI
 * @classdesc command line interface to sprout
###

class CLI extends EventEmitter

  ###*
   * Creates and sets up the argument parser, then calls the config functions
   * for each of the subcommands.
   *
   * @param {Boolean} debug - if debug is true, arg parse errors throw rather
   *                          than exiting the process.
  ###

  constructor: (opts = {}) ->
    @parser = new ArgParse
      version: pkg.version
      description: pkg.description
      debug: opts.debug || false
    sub = @parser.addSubparsers()

    $new(sub)
    $watch(sub)
    $compile(sub)
    $tpl(sub)
    $clean(sub)

  ###*
   * Parses the arguments, runs the command
   *
   * @param {String|Array} args - a string or array of command line arguments
   * @return {Promise} a promise for the command's results
  ###

  run: (args) ->
    if typeof args is 'string' then args = args.split(' ')
    args = @parser.parseArgs(args)

    fn = require(".#{path.sep}#{args.fn}")
    delete args.fn
    fn(@, args)

  ###*
   * @private
  ###

  $new = (sub) ->
    s = sub.addParser 'new',
      aliases: ['init', 'create']
      help: 'Create a new roots project template'

    s.addArgument ['path'],
      help: "Path to initialize your project at"

    s.addArgument ['--template', '-t'],
      help: "The template to use for your project"

    s.addArgument ['--overrides', '-o'],
      type: keyVal
      help: "Pass information directly to the template without answering
      questions. Accepts a quoted comma-separated key-value list, like
      'a: b, c: d'"

    s.setDefaults(fn: 'new')

  $watch = (sub) ->
    s = sub.addParser 'watch',
      help: 'Compile a roots project, serve it, and open it in a browser, then
      recompile when a files changes and refresh the page'

    s.addArgument ['path'],
      nargs: '?'
      defaultValue: process.cwd()
      help: "Path to a project that you would like to watch"

    s.addArgument ['--env', '-e'],
      defaultValue: process.env or 'development'
      help: "Your project's environment"

    s.addArgument ['--no-open'],
      action: 'storeTrue'
      help: "If present, this command will not automatically open a browser
      window"

    s.addArgument ['--port', '-p'],
      type: Number
      defaultValue: 1111
      help: "Port you want to run the local server on (default 1111)"

    s.setDefaults(fn: 'watch')

  $compile = (sub) ->
    s = sub.addParser 'compile',
      help: 'Compile a roots project'

    s.addArgument ['path'],
      nargs: '?'
      defaultValue: process.cwd()
      help: "Path to a project that you would like to compile"

    s.addArgument ['--env', '-e'],
      defaultValue: process.env or 'development'
      help: "Your project's environment"

    s.setDefaults(fn: 'compile')

  $tpl = (sub) ->
    main = sub.addParser 'template',
      aliases: ['tpl']
      help: "Manage roots' new project templates"

    sub = main.addSubparsers()

    # add

    s = sub.addParser 'add',
      alises: ['install']
      help: 'Add a new template for future use'

    s.addArgument ['name'],
      nargs: '?'
      help: "What you'd like to name the template"

    s.addArgument ['uri'],
      help: "A git-clone-able url or path for the template"

    s.setDefaults(fn: 'tpl/add')

    # remove

    s = sub.addParser ['remove'],
      help: 'Remove an existing template'

    s.addArgument ['name'],
      help: "Name of the template you'd like to remove"

    s.setDefaults(fn: 'tpl/remove')

    # list

    s = sub.addParser ['list'],
      help: 'List all of the templates you have installed'

    s.setDefaults(fn: 'tpl/list')

    # default

    s = sub.addParser ['default'],
      help: 'Make a certain template your default'

    s.addArgument ['name'],
      help: "Name of the template you'd like to make the default"

    s.setDefaults(fn: 'tpl/default')

    # reset

    s = sub.addParser ['reset'],
      help: 'Reset all existing information about templates'

    s.setDefaults(fn: 'tpl/reset')

  $clean = (sub) ->
    s = sub.addParser 'clean',
      help: 'Remove the output folder from a roots project'

    s.addArgument ['path'],
      nargs: '?'
      defaultValue: process.cwd()
      help: "Path to a project that you'd like to remove the output from"

    s.setDefaults(fn: 'clean')

  ###*
   * A simple csv-like string to object parser. Takes in "foo: bar, baz: quux",
   * and outputs a javascript object.
   *
   * @param {String} str - input string
   * @return {Object} javascript object output
  ###

  keyVal = (str) ->
    str.split(',').reduce (m, i) ->
      s = i.split(':').map((i) -> i.trim())
      m[s[0]] = s[1]; m
    , {}

module.exports = CLI