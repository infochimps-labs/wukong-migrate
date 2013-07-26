class EsMigrationDsl < Wukong::Migration::Dsl
  include EsHttpOperation::Helpers

  def self.template name
    <<-TEMPLATE.gsub(/^ {6}/, '').strip
      EsMigration.define '#{name}' do
        # Use dsl methods to: 
        # * create/update/delete indices
        # * update index settings
        # * add/remove aliases
        # * create/update/delete mappings using models defined in app/models
        #
        # create_index(:index_name) do
        #   number_of_replicas 5
        #   alias_to [:alias_one, :alias_two]
        #   create_mapping(:model_name) do
        #     dynamic true
        #     ttl     true
        #   end
        # end
      end
    TEMPLATE
  end

  def operation_list
    @operation_list ||= []
  end

end

class ObjectDsl < EsMigrationDsl
  # Additional mapping-level settings
  magic :source,         :boolean, doc: 'Should the raw JSON be indexed under _source'
  magic :dynamic,        :boolean, doc: 'Should the document schema be dynamic'
  magic :all,            :boolean, doc: 'Should the document be indexed in _all'
  magic :timestamp,      :boolean, doc: 'Should the _timestamp be indexed'
  magic :ttl,            String,   doc: 'Enable _ttl with a default time'
  magic :analyzer_field, String,   doc: 'Specify a field this document should use as an analyzer'
  magic :boost_field,    String,   doc: 'Specify a field this document should use as a boost'
  magic :parent,         String,   doc: 'Specify this documents _parent type'
  magic :routing,        String,   doc: 'Specify a field this document should use to route'
  
  def mapping_rules
    {}.tap do |rules|
      rules[:dynamic]    = dynamic                         if attribute_set?(:dynamic)
      rules[:_all]       = { enabled: all                } if attribute_set?(:all)
      rules[:_source]    = { enabled: source             } if attribute_set?(:source)
      rules[:_ttl]       = { enabled: true, default: ttl } if attribute_set?(:ttl)
      rules[:_timestamp] = { enabled: timestamp          } if attribute_set?(:timestamp)
      rules[:_analyzer]  = { path: analyzer_field        } if attribute_set?(:analyzer_field)
      rules[:_boost]     = { name: boost_field           } if attribute_set?(:boost_field)
      rules[:_parent]    = { type: parent                } if attribute_set?(:parent)
      rules[:_routing]   = { path: routing               } if attribute_set?(:routing)
    end
  end

  def model_mapping
    name.to_s.camelize.constantize.to_mapping
  end

  def to_mapping
    model_mapping.merge(mapping_rules)
  end
end

class IndexDsl < EsMigrationDsl
  # Dsl methods
  collection :creations,    ObjectDsl, singular_name: 'create_mapping'
  collection :updates,      ObjectDsl, singular_name: 'update_mapping'
  collection :deletions,    ObjectDsl, singular_name: 'delete_mapping'
  magic      :alias_to,     Array,     of: Symbol, default: []
  magic      :remove_alias, Array,     of: Symbol, default: []
    
  # Additional index-level settings
  magic      :number_of_replicas, Integer

  def receive_create_mapping(attrs, &block)
    obj = ObjectDsl.receive(attrs, &block)
    operation_list << update_mapping_op(self.name, obj.name, obj.to_mapping)
    obj
  end

  def receive_update_mapping(attrs, &block)
    obj = ObjectDsl.receive(attrs, &block)
    operation_list << update_mapping_op(self.name, obj.name, obj.to_mapping)
    obj
  end

  def receive_delete_mapping(attrs, &block)
    obj = ObjectDsl.receive(attrs, &block)
    operation_list.unshift update_mapping_op(self.name, obj.name, obj.to_mapping)
    obj
  end

  def receive_alias_to params
    params.each{ |als| operation_list << alias_index_op(:add, self.name, als) }
    super(params)
  end

  def receive_remove_alias params
    params.each{ |als| operation_list << alias_index_op(:remove, self.name, als) }
    super(params)
  end

  def index_settings
    { number_of_replicas: number_of_replicas }.compact_blank
  end

end

class EsMigration < EsMigrationDsl
  collection :creations, IndexDsl, singular_name: 'create_index'
  collection :updates,   IndexDsl, singular_name: 'update_index'
  collection :deletions, IndexDsl, singular_name: 'delete_index'

  def receive_create_index(attrs, &block)
    idx = IndexDsl.receive(attrs, &block)
    operation_list << create_index_op(idx.name, idx.index_settings)
    idx
  end

  def receive_update_index(attrs, &block)
    idx = IndexDsl.receive(attrs, &block)
    operation_list << update_settings_op(idx.name, idx.index_settings)
    idx
  end

  def receive_delete_index(attrs, &block)
    idx = IndexDsl.receive(attrs, &block)
    operation_list.unshift delete_index_op(idx.name)
    idx
  end

  def nested_operations
    (creations.to_a + updates.to_a).map{ |idx| idx.operation_list }.flatten
  end

  def combined_operations
    operation_list + nested_operations
  end

  def perform(options = {})
    combined_operations.each do |op|
      op.configure_with options
      log.info  op.info
      log.debug op.raw_curl_string
      response = op.execute
      log.debug [response.code, response.parsed_response].join(' ')
      if response.code == 200
        log.info 'Operation complete'
      else
        log.error response.parsed_response
        break unless options[:force]
      end
    end
  end
end
