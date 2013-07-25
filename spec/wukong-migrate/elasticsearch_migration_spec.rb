require 'spec_helper'

describe EsMigration do
  include EsHttpOperation::Helpers
  
  subject{ described_class }
  
  class SimpleModel
    include Gorillib::Model    
    field :test_field, Integer
  end
    
  context '#combined_operations' do
    it 'handles index operations' do
      subject.new do
        create_index(:foo)
      end.combined_operations.should eq([create_index_op('foo', {})])
    end

    it 'handles index settings' do
      subject.new do
        update_index(:foo) do
          number_of_replicas 6
        end
      end.combined_operations.should eq([update_settings_op('foo', { number_of_replicas: 6 })])
    end
    
    it 'handles delete operations first' do
      subject.new do
        create_index(:foo)
        delete_index(:bar)
      end.combined_operations.should eq([delete_index_op('bar'),
                                         create_index_op('foo', {})])
    end
    
    it 'handles alias operations last' do
      m = subject.new do
        create_index(:foo) do
          alias_to [:superfoo, :superbar]
        end
        delete_index(:bar)
      end.combined_operations.should eq([delete_index_op('bar'),
                                         create_index_op('foo', {}),
                                         alias_index_op('add', 'foo', 'superfoo'),
                                         alias_index_op('add', 'foo', 'superbar')])
    end
    
    it 'handles mapping operations' do 
      subject.new do
        update_index(:foo) do
          create_mapping(:simple_model)
        end
      end.combined_operations.should eq([update_settings_op('foo', {}),
                                         update_mapping_op('foo', 'simple_model', SimpleModel.to_mapping)])
      
    end
    
    it 'handles mapping settings' do
      subject.new do
        update_index(:foo) do
          create_mapping(:simple_model) do
            dynamic true
          end
        end
      end.combined_operations.should eq([update_settings_op('foo', {}),
                                         update_mapping_op('foo', 'simple_model', SimpleModel.to_mapping.merge(dynamic: true))])
    end
  end
end
