$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))
require 'sloc'

require 'bacon'
Bacon.summary_on_exit

describe 'SLOC' do
  describe 'Ruby parser' do
    @parser = SLOC::Counter.new('ruby', 'RubyParser')

    def sloc(string)
      @parser.string(string)
    end

    should 'count single line comment' do
      sloc("#").should == {:comment => 1}
      sloc("# something").should == {:comment => 1}
      sloc("# something\n# else").should == {:comment => 2}
    end

    should 'count multi line comment' do
      sloc("=begin\nsomething\n=end").should == {:comment => 1}
      sloc("=begin\nsomething\nelse\n=end").should == {:comment => 2}
    end

    should 'count code' do
      sloc("puts hi").should == {:code => 1}
      sloc("puts hi\n1 * 100").should == {:code => 2}
    end

    should 'count code with comment on same line' do
      sloc("puts hi\n1 * 100 # comment").should == {:code => 2, :comment => 1}
    end
  end
end
