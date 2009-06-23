module SLOC
  # @example usage
  # p SLOC::Counter.new('ruby', 'RubyParser').glob('~/github/manveru/innate/lib/**/*.rb')
  class Counter
    def initialize(file, name)
      Treetop.load(File.join(GRAMMAR_ROOT, "#{file}.tt"))
      @parser = Module.const_get(name).new
    end

    def glob(*files)
      files.each_with_object(Hash.new(0)) do |file, total|
        Dir.glob File.expand_path(file) do |path|
          file(path, total)
        end
      end
    end

    def file(file, total = Hash.new(0))
      SLOC.aggregate(@parser.parse(File.read(file)).count, total)
    rescue => ex
      p ex
      raise "In #{file} - #{@parser.failure_reason}"
    end

    def string(string, total = Hash.new(0))
      SLOC.aggregate(@parser.parse(string).count, total)
    rescue => ex
      p ex
      raise @parser.failure_reason.dump
    end
  end
end
