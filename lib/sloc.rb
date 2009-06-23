require 'pathname'

require 'treetop'

require 'sloc/counter'

module SLOC
  GRAMMAR_ROOT = File.expand_path('../sloc/grammar/', __FILE__)

  COUNTERS_NAMES = {
    :ruby => 'RubyParser',
    :sh => 'ShParser',
  }

  module_function

  def counter_for(type)
    if name = COUNTERS_NAMES[type]
      Counter.new(type.to_s, name)
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

  def file(filename, override_type = nil)
    path = Pathname(filename.to_s)
    path = path.readlink if path.symlink?

    return unless path.file?

    type = override_type || detect_ext(path) || detect_shebang(path)

    if counter = counter_for(type)
      count = counter.file(path)
      yield count if count && block_given?
      count
    end
  end

  def detect_ext(path)
    case path.extname
    when /\.(rb|rake)$/
      :ruby
    when /\.(sh|zsh)$/
      :sh
    end
  end

  def detect_shebang(path)
    shebang = path.open{|io| io.gets }
    return unless shebang && shebang.valid_encoding?

    if shebang =~ /^#!/
      case shebang
      when /ruby/
        :ruby
      when /zsh/
        :sh
      else
        warn "Unknown ext of %p, shebang detection for %p failed as well." % [path.to_s, shebang]
      end
    else
      warn "Unknown ext of %p, no shebang found." % [path.to_s]
    end
  end

  def aggregate(to_add, total = Hash.new(0))
    to_add.each{|name, amount| total[name] += amount }
    total
  end
end
