require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
describe DataMapper::Adapters::RetsAdapter do
  describe 'in isolation' do 
    before :all do
      @adapter = DataMapper.setup(:default, :url => 'example.com', :username => 'mc', :password => 'p@$$', :adapter => 'rets')
      class ::Heffalump
        include DataMapper::Resource
        storage_names[:default] = { :resource => 'PROPERTY', :class => 'RES' }

        property :id,        Serial 
        property :color,     String , :field => 'COLOR'
        property :num_spots, Integer
        property :striped,   Boolean, :field => 'STRIPEDYN'
        property :birthday,  Time, :field => 'CREATED'
      end
    end

    describe 'Resource' do
      it' should use this adapter' do 
        Heffalump.repository.adapter.should === @adapter
      end
    end

    describe '#read' do
      before do
        @client = double(RETS4R::Client, :login => nil, :logger= => nil, :search => double(RETS4R::Client::Transaction, :response => []) ) 
        RETS4R::Client.stub!(:new).and_yield(@client)
      end

      describe "all" do
        it 'should create a new client with the option url' do
          RETS4R::Client.should_receive(:new).with('example.com')
        end
        it 'should log in with the option user and pass' do
          @client.should_receive(:login).with('mc', 'p@$$')
        end
        it 'should search with the storage name class and resource' do
          @client.should_receive(:search).with('PROPERTY','RES', anything, anything)
        end
        it 'should pass the select to search' do
          @client.should_receive(:search).with(anything,anything,anything,hash_including('Select' => 'id,COLOR,num_spots,STRIPEDYN,CREATED'))
        end
        it 'should set the logger to the datamapper logger' do
          DataMapper.stub!(:logger).and_return('fake logger')
          @client.should_receive(:logger=).with('fake logger')
        end
        after do
          Heffalump.all.should be_empty
        end
      end

      describe 'dmql' do
        def query_should_include( clause )
          @client.should_receive(:search).with do |bla,bla,query,bla|
            query.should include( clause )
          end
        end
        it 'should generate range list field criteria' do
           query_should_include '(num_spots=1-5)'
        end
        it 'should generate equality field criteria' do
           query_should_include '(COLOR=RED)'
        end
        it 'should generate lt field criteria' do
          query_should_include '(CREATED=1985-04-05T00:00:00-)'
        end
        after do
          Heffalump.all(:num_spots => 1..5, :color => 'RED', :birthday.lt => Time.parse('1985-04-05') ).should be_empty
        end
      end

      it 'should not raise any errors' do
        lambda {
          Heffalump.all()
        }.should_not raise_error
      end

      it 'should pass the limit to the client' do
        @client.should_receive(:search).with(anything,anything,anything,hash_including('Limit' => '5'))
        Heffalump.all(:limit => 5).should be_empty
      end

      describe 'when the client finds stuff' do
        before do
          @attributes = {
            'COLOR' => 'brownish hue',
            'id' => '1',
            'num_spots' => '3',
            'STRIPEDYN' => 'Y',
            'CREATED' => '2007-03-21 05:01:40'
          }
          @client.should_receive(:search).and_return(double(RETS4R::Client::Transaction, :response => [@attributes]))
        end
        it 'should map boolians' do
          pending
          Heffalump.first.attributes[:striped].should == true 
        end
        it 'should return stuff' do
          all = Heffalump.all
          all.should have(1).heffalump
          all.first.attributes.should == { 
            :color => 'brownish hue', 
            :striped => 'Y', 
            :num_spots => 3, 
            :id => 1, 
            :birthday => Time.parse('2007-03-21T05:01:40')} 
        end
      end
    end
  end

  describe 'in the real world' do
    before :all do
      # http://www.crt.realtors.org/projects/rets/variman/demo/
      
      DataMapper::Logger.new(STDERR, :debug)
      @adapter = DataMapper.setup(:default, 
                                  :url => 'http://demo.crt.realtors.org:6103/rets/login', 
                                  :username => 'Joe', :password => 'Schmoe', :adapter => 'rets')
      class ::Property
        include DataMapper::Resource
        storage_names[:default] = { :resource => 'PROPERTY', :class => 'RES' }

        property :id, Serial, :field => 'UID'
        property :mls, Integer, :field => 'MLSNUM'
        property :beds, Integer, :field => 'BEDS'
        property :modified, DateTime, :field => 'MODIFIED'
      end
    end
    describe 'by identifier' do
      before do
        @all = Property.all(:id => 9895)
        @the = @all.first
      end
      it { @all.size.should  == 1 }
      it { @the.id.should  == 9895 }
      it { @the.mls.should == 9895 }
      it { @the.beds.should == 4 }
      it { @the.modified.should == DateTime.parse('2007-03-21T04:47:01') }
    end
    describe 'query matching' do
      before :all do
        #@red  = Property.first :color => 'red' 
        @two  = Property.first :beds => 2, :modified.lt => DateTime.parse('2008-01-01'), :limit => 1
        @five = Property.first :beds => 5, :modified.lt => DateTime.parse('2008-01-01'), :limit => 1
      end

      describe 'conditions' do
        describe 'eql' do
          it 'should be able to find with values included in an exclusive range of values' do
            Property.all(:beds => 1...5).should be_include(@five)
          end

          it 'should not be able to find with values not included in an inclusive range of values' do
            Property.all(:beds => 1..4).should_not be_include(@five)
          end
        end

        describe 'not' do
           before {pending}

          it 'should be able to search for objects with not equal value' do
            Property.all(:color.not => 'red').should_not be_include(@red)
          end

          it 'should include objects that are not like the value' do
            Property.all(:color.not => 'black').should be_include(@red)
          end

          it 'should be able to search for objects with not nil value' do
            Property.all(:color.not => nil).should be_include(@red)
          end

          it 'should not include objects with a nil value' do
            Property.all(:color.not => nil).should_not be_include(@two)
          end

          it 'should be able to search for object with a nil value using required properties' do
            Property.all(:id.not => nil).should == [ @red, @two, @five ]
          end

          it 'should be able to search for objects not in an empty list (match all)' do
            Property.all(:color.not => []).should == [ @red, @two, @five ]
          end

          it 'should be able to search for objects in an empty list and another OR condition (match none on the empty list)' do
            Property.all(:conditions => DataMapper::Query::Conditions::Operation.new(
              :or,
              DataMapper::Query::Conditions::Comparison.new(:in, Property.properties[:color], []),
              DataMapper::Query::Conditions::Comparison.new(:in, Property.properties[:num_spots], [5]))).should == [ @five ]
          end

          it 'should be able to search for objects not included in an array of values' do
            Property.all(:num_spots.not => [ 1, 3, 5, 7 ]).should be_include(@two)
          end

          it 'should be able to search for objects not included in an array of values' do
            Property.all(:num_spots.not => [ 1, 3, 5, 7 ]).should_not be_include(@five)
          end

          it 'should be able to search for objects not included in an inclusive range of values' do
            Property.all(:num_spots.not => 1..4).should be_include(@five)
          end

          it 'should be able to search for objects not included in an exclusive range of values' do
            Property.all(:num_spots.not => 1...5).should be_include(@five)
          end

          it 'should not be able to search for values not included in an inclusive range of values' do
            Property.all(:num_spots.not => 1..5).should_not be_include(@five)
          end

          it 'should not be able to search for values not included in an exclusive range of values' do
            Property.all(:num_spots.not => 1...6).should_not be_include(@five)
          end
        end

        describe 'like' do
          before { pending }
          it 'should be able to search for objects that match value' do
            Property.all(:color.like => '%ed').should be_include(@red)
          end

          it 'should not search for objects that do not match the value' do
            Property.all(:color.like => '%blak%').should_not be_include(@red)
          end
        end

        describe 'regexp' do
          before { pending }

          it 'should be able to search for objects that match value' do
            Property.all(:color => /ed/).should be_include(@red)
          end

          it 'should not be able to search for objects that do not match the value' do
            Property.all(:color => /blak/).should_not be_include(@red)
          end

          it 'should be able to do a negated search for objects that match value' do
            Property.all(:color.not => /blak/).should be_include(@red)
          end

          it 'should not be able to do a negated search for objects that do not match value' do
            Property.all(:color.not => /ed/).should_not be_include(@red)
          end
        end

        describe 'gt' do
          before { pending }
          it 'should be able to search for objects with value greater than' do
            Property.all(:num_spots.gt => 1).should be_include(@two)
          end

          it 'should not find objects with a value less than' do
            Property.all(:num_spots.gt => 3).should_not be_include(@two)
          end
        end

        describe 'gte' do
          before { pending }
          it 'should be able to search for objects with value greater than' do
            Property.all(:num_spots.gte => 1).should be_include(@two)
          end

          it 'should be able to search for objects with values equal to' do
            Property.all(:num_spots.gte => 2).should be_include(@two)
          end

          it 'should not find objects with a value less than' do
            Property.all(:num_spots.gte => 3).should_not be_include(@two)
          end
        end

        describe 'lt' do
          it 'should be able to search for objects with value less than' do
            Property.all(:beds.lt => 3).should be_include(@two)
          end

          it 'should not find objects with a value less than' do
            #by default it only returns 50 at a time... we are going to have to get more specific here somehow.
            Property.all(:beds.gt => 2).should_not be_include(@two)
          end
        end

        describe 'lte' do
          before { pending } 
          it 'should be able to search for objects with value less than' do
            Property.all(:num_spots.lte => 3).should be_include(@two)
          end

          it 'should be able to search for objects with values equal to' do
            Property.all(:num_spots.lte => 2).should be_include(@two)
          end

          it 'should not find objects with a value less than' do
            Property.all(:num_spots.lte => 1).should_not be_include(@two)
          end
        end
      end
    end
  end
end
