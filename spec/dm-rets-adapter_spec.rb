require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
describe DataMapper::Adapters::RetsAdapter do
  before :all do
    @adapter = DataMapper.setup(:default, :hostname => 'example.com', :username => 'mc', :password => 'p@$$', :adapter => 'rets')

    class ::Heffalump
      include DataMapper::Resource

      property :id,        Serial
      property :color,     String
      property :num_spots, Integer
      property :striped,   Boolean
    end

  end

  describe '#read' do
    before do
      pending
      @heffalump = double("Heffalump", :color => 'brownish hue')
    end

    it 'should not raise any errors' do
      lambda {
        Heffalump.all()
      }.should_not raise_error
    end

    it 'should return stuff' do
      Heffalump.all.should be_include(@heffalump)
    end
  end
  describe 'query matching' do
    before :all do
      @red  = double Heffalump, :color => 'red' 
      @two  = double Heffalump, :num_spots => 2 
      @five = double Heffalump, :num_spots => 5
    end

    describe 'conditions' do
      describe 'eql' do
        before {pending}
        it 'should be able to search for objects included in an inclusive range of values' do
          Heffalump.all(:num_spots => 1..5).should be_include(@five)
        end

        it 'should be able to search for objects included in an exclusive range of values' do
          Heffalump.all(:num_spots => 1...6).should be_include(@five)
        end

        it 'should not be able to search for values not included in an inclusive range of values' do
          Heffalump.all(:num_spots => 1..4).should_not be_include(@five)
        end

        it 'should not be able to search for values not included in an exclusive range of values' do
          Heffalump.all(:num_spots => 1...5).should_not be_include(@five)
        end
      end

      describe 'not' do
         before {pending}

        it 'should be able to search for objects with not equal value' do
          Heffalump.all(:color.not => 'red').should_not be_include(@red)
        end

        it 'should include objects that are not like the value' do
          Heffalump.all(:color.not => 'black').should be_include(@red)
        end

        it 'should be able to search for objects with not nil value' do
          Heffalump.all(:color.not => nil).should be_include(@red)
        end

        it 'should not include objects with a nil value' do
          Heffalump.all(:color.not => nil).should_not be_include(@two)
        end

        it 'should be able to search for object with a nil value using required properties' do
          Heffalump.all(:id.not => nil).should == [ @red, @two, @five ]
        end

        it 'should be able to search for objects not in an empty list (match all)' do
          Heffalump.all(:color.not => []).should == [ @red, @two, @five ]
        end

        it 'should be able to search for objects in an empty list and another OR condition (match none on the empty list)' do
          Heffalump.all(:conditions => DataMapper::Query::Conditions::Operation.new(
            :or,
            DataMapper::Query::Conditions::Comparison.new(:in, Heffalump.properties[:color], []),
            DataMapper::Query::Conditions::Comparison.new(:in, Heffalump.properties[:num_spots], [5]))).should == [ @five ]
        end

        it 'should be able to search for objects not included in an array of values' do
          Heffalump.all(:num_spots.not => [ 1, 3, 5, 7 ]).should be_include(@two)
        end

        it 'should be able to search for objects not included in an array of values' do
          Heffalump.all(:num_spots.not => [ 1, 3, 5, 7 ]).should_not be_include(@five)
        end

        it 'should be able to search for objects not included in an inclusive range of values' do
          Heffalump.all(:num_spots.not => 1..4).should be_include(@five)
        end

        it 'should be able to search for objects not included in an exclusive range of values' do
          Heffalump.all(:num_spots.not => 1...5).should be_include(@five)
        end

        it 'should not be able to search for values not included in an inclusive range of values' do
          Heffalump.all(:num_spots.not => 1..5).should_not be_include(@five)
        end

        it 'should not be able to search for values not included in an exclusive range of values' do
          Heffalump.all(:num_spots.not => 1...6).should_not be_include(@five)
        end
      end

      describe 'like' do
        before { pending }
        it 'should be able to search for objects that match value' do
          Heffalump.all(:color.like => '%ed').should be_include(@red)
        end

        it 'should not search for objects that do not match the value' do
          Heffalump.all(:color.like => '%blak%').should_not be_include(@red)
        end
      end

      describe 'regexp' do
        before { pending }
        it 'should be able to search for objects that match value' do
          Heffalump.all(:color => /ed/).should be_include(@red)
        end

      it 'should not be able to search for objects that do not match the value' do
        Heffalump.all(:color => /blak/).should_not be_include(@red)
        end

        it 'should be able to do a negated search for objects that match value' do
          Heffalump.all(:color.not => /blak/).should be_include(@red)
        end

        it 'should not be able to do a negated search for objects that do not match value' do
          Heffalump.all(:color.not => /ed/).should_not be_include(@red)
        end

      end

      describe 'gt' do
        before { pending }
        it 'should be able to search for objects with value greater than' do
          Heffalump.all(:num_spots.gt => 1).should be_include(@two)
        end

        it 'should not find objects with a value less than' do
          Heffalump.all(:num_spots.gt => 3).should_not be_include(@two)
        end
      end

      describe 'gte' do
        before { pending }
        it 'should be able to search for objects with value greater than' do
          Heffalump.all(:num_spots.gte => 1).should be_include(@two)
        end

        it 'should be able to search for objects with values equal to' do
          Heffalump.all(:num_spots.gte => 2).should be_include(@two)
        end

        it 'should not find objects with a value less than' do
          Heffalump.all(:num_spots.gte => 3).should_not be_include(@two)
        end
      end

      describe 'lt' do
        before { pending }
        it 'should be able to search for objects with value less than' do
          Heffalump.all(:num_spots.lt => 3).should be_include(@two)
        end

        it 'should not find objects with a value less than' do
          Heffalump.all(:num_spots.gt => 2).should_not be_include(@two)
        end
      end

      describe 'lte' do
        before do
          pending
        end
        it 'should be able to search for objects with value less than' do
          Heffalump.all(:num_spots.lte => 3).should be_include(@two)
        end

        it 'should be able to search for objects with values equal to' do
          Heffalump.all(:num_spots.lte => 2).should be_include(@two)
        end

        it 'should not find objects with a value less than' do
          Heffalump.all(:num_spots.lte => 1).should_not be_include(@two)
        end
      end
  end

    describe 'limits' do
      before do
        pending
      end
      it 'should be able to limit the objects' do
        Heffalump.all(:limit => 2).length.should == 2
      end
    end
  end
end
