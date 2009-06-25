require 'pathname'

require 'treetop'

require 'sloc/counter'

module SLOC
  GRAMMAR_ROOT = File.expand_path('../sloc/grammar/', __FILE__)

  SYNTAX_LIST = {}
  COUNTER_CACHE = {}

  module_function

  def syntax(name, ext, shebang = nil)
    SYNTAX_LIST[name] = [ext, shebang]
  end

  #      name         ext             shebang
  syntax :ruby,       /\.(rb|rake)$/, /ruby/
  syntax :sh,         /\.(sh|zsh)/,   /sh|zsh|bash/
  syntax :lisp,       /\.lisp/,       /lisp|scheme|sbcl/
  syntax :smalltalk,  /\.st/,         /gst/
  syntax :javascript, /\.js/,         /js/

  def counter_for(name)
    if found = SYNTAX_LIST[name]
      COUNTER_CACHE[name] ||= Counter.new(name.to_s, "#{name.to_s.capitalize}Parser")
    end
  end

  def glob(globname)
    total = Hash.new(0)

    Dir.glob(File.expand_path(globname)) do |path|
      file(path) do |count|
        aggregate(count, total)
      end
    end

    yield total if block_given?
    total
  end

  def file(filename, override_name = nil)
    path = Pathname(filename.to_s)
    path = path.readlink if path.symlink?

    return unless path.file?

    name = override_name || detect_ext(path) || detect_shebang(path)

    if counter = counter_for(name)
      count = counter.file(path)
      yield count if count && block_given?
      count
    end
  end

  def detect_ext(path)
    extname = path.extname

    SYNTAX_LIST.find do |key, (ext, shebang)|
      return key if extname =~ ext
    end
  end

  def detect_shebang(path)
    shebang = path.open{|io| io.gets }
    return unless shebang && shebang.valid_encoding?

    if shebang =~ /^#!/
      SYNTAX_LIST.find do |key, (ext, l_shebang)|
        return key if shebang && shebang =~ l_shebang
      end
      warn "Unknown ext of %p, shebang detection for %p failed as well." % [path.to_s, shebang]
    else
      warn "Unknown ext of %p, no shebang found." % [path.to_s]
    end
  end

  def aggregate(to_add, total = Hash.new(0))
    to_add.each{|name, amount| total[name] += amount }
    total
  end
end
