fs = require 'fs'
{SymbolIndex} = require '../lib/symbols'
{getGrammar, expectSymbol, expectSymbolLength, len} = require './spec-utils'

FILE_PATH = './data/pince.js'

text = '''
(function() {
  var EventEmitter, LOG_PREFIX, Listener, Logger, clc, colors, defaultLogLevel, k, listener, moment, name, output, specificLogLevels, v, __extend, __levelnums, __loggerLevel, __onError, __specificLoggerLevels, _ref,
    __slice = [].slice,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  clc = require('cli-color');

  moment = require('moment');

  EventEmitter = require('events').EventEmitter;

  LOG_PREFIX = 'MADEYE_LOGLEVEL';

  defaultLogLevel = process.env[LOG_PREFIX];

  specificLogLevels = {};

  _ref = process.env;
  for (k in _ref) {
    v = _ref[k];
    if (k.indexOf(LOG_PREFIX + "_") !== 0) {
      continue;
    }
    if (k === LOG_PREFIX) {
      continue;
    }
    name = k.substr((LOG_PREFIX + "_").length);
    name = name.split('_').join(':');
    specificLogLevels[name] = v;
  }

  colors = {
    error: clc.red.bold,
    warn: clc.yellow,
    info: clc.bold,
    debug: clc.blue,
    trace: clc.blackBright
  };

  output = function(data) {
    var color, messages, prefix, timestr;
    if (!data.message) {
      return;
    }
    timestr = moment(data.timestamp).format("YYYY-MM-DD HH:mm:ss.SSS");
    color = colors[data.level];
    prefix = timestr + " " + (color(data.level + ": ")) + " ";
    if (data.name) {
      prefix += "[" + data.name + "] ";
    }
    if ('string' === typeof data.message) {
      messages = [data.message];
    } else {
      messages = data.message;
    }
    messages.unshift(prefix);
    if (data.stderr) {
      return console.error.apply(console, messages);
    } else {
      return console.log.apply(console, messages);
    }
  };

  __extend = function() {
    var o, obj, others, _i, _len;
    obj = arguments[0], others = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    for (_i = 0, _len = others.length; _i < _len; _i++) {
      o = others[_i];
      for (k in o) {
        if (!__hasProp.call(o, k)) continue;
        v = o[k];
        obj[k] = v;
      }
    }
    return obj;
  };

  __levelnums = {
    error: 0,
    warn: 1,
    info: 2,
    debug: 3,
    trace: 4
  };

  __loggerLevel = defaultLogLevel;

  __specificLoggerLevels = specificLogLevels;

  __onError = null;

  Listener = (function() {
    function Listener(options) {
      var _ref1, _ref2;
      if (options == null) {
        options = {};
      }
      if ('string' === typeof options) {
        options = {
          logLevel: options
        };
      }
      this.logLevel = (_ref1 = options.logLevel) != null ? _ref1 : __loggerLevel;
      this.logLevels = (_ref2 = options.logLevels) != null ? _ref2 : __specificLoggerLevels;
      this.loggers = {};
      this.listenFns = {};
    }

    Listener.prototype._reattachLoggers = function() {
      var logger, _ref1, _results;
      _ref1 = this.loggers;
      _results = [];
      for (name in _ref1) {
        logger = _ref1[name];
        this.detach(name);
        _results.push(this.listen(logger, name));
      }
      return _results;
    };

    Listener.prototype.setLevel = function(name, level) {
      var levels;
      if (level) {
        if (!name) {
          throw new Error('Must supply a name');
        }
        levels = {};
        levels[name] = level;
        this.setLevels(levels);
        return;
      }
      level = name;
      if (!level) {
        throw new Error('Must supply a level');
      }
      if (this.logLevel === level) {
        return;
      }
      this.logLevel = level;
      this._reattachLoggers();
    };

    Listener.prototype.setLevels = function(levels) {
      var level;
      for (name in levels) {
        level = levels[name];
        this.logLevels[name] = level;
      }
      this._reattachLoggers();
    };

    Listener.prototype.findLevelFor = function(name) {
      var lastIdx, level, parentLevel, parentName;
      level = this.logLevels[name];
      parentName = name;
      while ((parentName.indexOf(':') > -1) && !level) {
        lastIdx = parentName.lastIndexOf(':');
        parentName = parentName.substr(0, lastIdx);
        parentLevel = this.logLevels[parentName];
        if (level == null) {
          level = parentLevel;
        }
        if (level) {
          break;
        }
      }
      if (level == null) {
        level = this.logLevel;
      }
      return level;
    };

    Listener.prototype.listen = function(logger, name) {
      var errorFn, level;
      if (!logger) {
        throw Error("An object is required for logging!");
      }
      if (!name) {
        throw Error("Name is required for logging!");
      }
      this.loggers[name] = logger;
      if (level) {
        this.logLevels[name] = level;
      }
      level = this.findLevelFor(name);
      this.listenFns[name] = {};
      ['warn', 'info', 'debug', 'trace'].forEach((function(_this) {
        return function(l) {
          var listenFn, useStderr;
          if (__levelnums[l] > __levelnums[level]) {
            return;
          }
          useStderr = __levelnums[l] <= __levelnums['warn'];
          listenFn = function() {
            var msgs;
            msgs = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
            return output({
              timestamp: new Date,
              level: l,
              name: name,
              message: msgs,
              stderr: useStderr
            });
          };
          logger.on(l, listenFn);
          return _this.listenFns[name][l] = listenFn;
        };
      })(this));
      errorFn = (function(_this) {
        return function() {
          var msgs, shouldPrint;
          msgs = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          shouldPrint = typeof __onError === "function" ? __onError(msgs) : void 0;
          if (shouldPrint !== false) {
            return output({
              timestamp: new Date,
              level: 'error',
              name: name,
              message: msgs,
              stderr: true
            });
          }
        };
      })(this);
      logger.on('error', errorFn);
      this.listenFns[name]['error'] = errorFn;
    };

    Listener.prototype.detach = function(name) {
      var level, listenFn, logger, _ref1;
      logger = this.loggers[name];
      if (!logger) {
        return;
      }
      _ref1 = this.listenFns[name];
      for (level in _ref1) {
        listenFn = _ref1[level];
        logger.removeListener(level, listenFn);
      }
      delete this.listenFns[name];
      delete this.loggers[name];
    };

    return Listener;

  })();

  listener = new Listener();

  Logger = (function(_super) {
    __extends(Logger, _super);

    function Logger(options) {
      if (options == null) {
        options = {};
      }
      if ('string' === typeof options) {
        options = {
          name: options
        };
      }
      this.name = options.name;
      listener.listen(this, options.name, options.logLevel);
    }

    Logger.setLevel = function(level) {
      return listener.setLevel.apply(listener, arguments);
    };

    Logger.setLevels = function(levels) {
      return listener.setLevels.apply(listener, arguments);
    };

    Logger.onError = function(callback) {
      return __onError = callback;
    };

    Logger.listen = function(logger, name, level) {
      return listener.listen(logger, name, level);
    };

    Logger.prototype._log = function(level, messages) {
      messages.unshift(level);
      return this.emit.apply(this, messages);
    };

    Logger.prototype.log = function() {
      var level, messages;
      level = arguments[0], messages = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      return this._log(level, messages);
    };

    Logger.prototype.trace = function() {
      var messages;
      messages = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this._log('trace', messages);
    };

    Logger.prototype.debug = function() {
      var messages;
      messages = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this._log('debug', messages);
    };

    Logger.prototype.info = function() {
      var messages;
      messages = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this._log('info', messages);
    };

    Logger.prototype.warn = function() {
      var messages;
      messages = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this._log('warn', messages);
    };

    Logger.prototype.error = function() {
      var messages;
      messages = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this._log('error', messages);
    };

    return Logger;

  })(EventEmitter);

  Logger.listener = listener;

  module.exports = Logger;

}).call(this);
'''

describe 'parseSymbols', ->
  # text = fs.readFileSync FILE_PATH
  grammar = null
  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('language-javascript')
    grammar = getGrammar 'js'

  it 'should parse the long file correctly', ->
    symbols = new SymbolIndex()
    fpath = 'x'
    symbols.parse fpath, text, grammar

    results = symbols.findAllPositions(fpath)
    expect(len(results) > 1).toBe(true);
    # TODO Do better checks for symbols in the text
