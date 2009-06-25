module SLOC
  # @example usage
  # p SLOC::Counter.new('ruby', 'RubyParser').glob('~/github/manveru/innate/lib/**/*.rb')
  class Counter
    def initialize(file, name)
      Treetop.load(File.join(GRAMMAR_ROOT, "#{file}.tt"))
      @parser_class = Module.const_get(name)
    rescue NameError
      Treetop.load(File.join(GRAMMAR_ROOT, "common.tt"))
      retry
    end

    def glob(*files)
      files.each_with_object(Hash.new(0)) do |file, total|
        Dir.glob File.expand_path(file) do |path|
          file(path, total)
        end
      end
    end

    def file(file, total = Hash.new(0))
      SLOC.aggregate(count(File.read(file)), total)
    rescue => ex
      p ex
      raise "In #{file} - #{@parser.failure_reason}"
    end

    def string(string, total = Hash.new(0))
      SLOC.aggregate(count(string), total)
    rescue => ex
      p ex
      raise @parser.failure_reason.dump
    end

    private

    def count(string)
      @parser = @parser_class.new
      @parser.parse(string).count
    ensure
      count_objects = ObjectSpace.count_objects
      total, free = count_objects.values_at(:TOTAL, :FREE)
      @parser = nil
      GC.start if free < 524288
    end
  end
end
