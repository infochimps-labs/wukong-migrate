require 'spec_helper'

describe Gorillib::Model do

  subject{ TestModel = Class.new(Object){ include Gorillib::Model } }

  after(:each) do
    Object.send(:remove_const, :TestModel)
  end
  
  context '#to_mapping' do
    it 'generates string mappings correctly' do
      subject.class_eval do
        field :foo, String, es_options: { analyzer: 'whitespace' }
      end
      subject.to_mapping.should eq({ properties: { foo: { type: 'string', index: 'not_analyzed', analyzer: 'whitespace', omit_norms: true, index_options: 'docs' } } })
    end

    it 'generates integer mappings correctly' do
      subject.class_eval do
        field :foo, Integer, es_options: { precision_step: 2 }
      end
      subject.to_mapping.should eq({ properties: { foo: { type: 'integer', precision_step: 2 } } })
    end

    it 'generates boolean mappings correctly' do
      subject.class_eval do
        field :foo, :boolean, es_options: { store: 'yes' }
      end
      subject.to_mapping.should eq({ properties: { foo: { type: 'boolean', store: 'yes' } } })
    end

    it 'generates date mappings correctly' do
      subject.class_eval do
        field :foo, Date, es_options: { format: 'basic_date' }
      end
      subject.to_mapping.should eq({ properties: { foo: { type: 'date', format: 'basic_date' } } })
    end

    it 'generates float mappings correctly' do
      subject.class_eval do
        field :foo, Float, es_options: { ignore_malformed: true }
      end
      subject.to_mapping.should eq({ properties: { foo: { type: 'float', ignore_malformed: true } } })
    end

    it 'generates array mappings correctly' do
      subject.class_eval do
        field :foo, Array, of: Float, es_options: { precision_step: 6 }
      end
      subject.to_mapping.should eq({ properties: { foo: { type: 'float', precision_step: 6 } } })    
    end

    it 'generates object mappings correctly' do
      subject.class_eval do
        class Bar
          include Gorillib::Model
          field :baz, String
        end

        field :bar, Bar      
      end
      subject.to_mapping.should eq({ properties: { bar: { properties: { baz: { type: 'string', index: 'not_analyzed', omit_norms: true, index_options: 'docs' } } } } })
    end
    
    it 'handles non-standard fields as strings' do
      subject.class_eval do
        class Baz
          def self.receive(param) param ; end
        end
        field :bar, Baz        
      end
      subject.to_mapping.should eq({ properties: { bar: { type: 'string', index: 'not_analyzed', omit_norms: true, index_options: 'docs' } } })
    end
  end
end

describe Gorillib::Builder do

  subject{ TestBuilder = Class.new(Object){ include Gorillib::Builder } }

  after(:each) do
    Object.send(:remove_const, :TestBuilder)
  end

  it 'allows receive overrides of magic fields' do
    subject.class_eval do
      magic :foo, String
      
      def receive_foo param 
        super(param + 'bar')
      end
    end
    subject.receive(foo: 'foo').foo.should eq('foobar')
  end
  
  it 'allows receive overrides of collection fields' do
    subject.class_eval do
      class Bar
        include Gorillib::Builder
        magic :baz, String
      end

      collection :bars, Bar
      
      def receive_bar(attrs, &block) 
        b = Bar.receive(attrs, &block)
        b.baz = 'foo' + b.baz
        b
      end
    end
    subject.new do
      bar(:bar) do
        baz 'baz'
      end
    end.bars[:bar].baz.should eq('foobaz')
  end
end
