class EsHttpOperation
  include Gorillib::Model
  include HTTParty 

  field :index, String

  def configure_with options
    uri = [options[:host], options[:port]].join(':')
    self.class.base_uri uri
  end
      
  def execute
    response = call_own_http_method
    response
  end

  def call_own_http_method
    http_options = body ? { body: json_body } : {}
    self.class.send(verb, path, http_options)
  end

  def raw_curl_string
    "curl -X #{verb.to_s.upcase} '#{self.class.base_uri}#{path}'".tap do |raw|
      raw << " -d '#{json_body}'" if body
    end
  end

  def json_body
    MultiJson.encode(body)
  end
  
  class CreateIndex < EsHttpOperation
    field :settings, Hash
    
    def path() File.join('', index, '')             ; end
    def body() { settings: settings }.compact_blank ; end
    def verb() :put                                 ; end
    def info() "Creating index #{index}"            ; end
  end
  
  class DeleteIndex < EsHttpOperation
    field :obj_type, String
    
    def path()  ['', index, obj_type, ''].compact.join('/') ; end  
    def body()  nil                                         ; end
    def verb() :delete                                      ; end
    def info() "Deleting index #{index}"                    ; end
  end
  
  class UpdateIndexSettings < EsHttpOperation
    field :settings, Hash
    
    def path() File.join('', index, '_settings?')     ; end
    def body() { index: settings }                    ; end
    def verb() :put                                   ; end
    def info() "Updating settings for index #{index}" ; end
  end
  
  class AliasIndex < EsHttpOperation
    field :alias_name, String
    field :action,     Symbol
    field :filter,     Hash
    
    def path() '/_aliases?'                                                                                  ; end
    def body() { actions: [{ action => { index: index, alias: alias_name, filter: filter }.compact_blank }]} ; end 
    def verb() :post                                                                                         ; end
    def info() "#{action.capitalize} alias :#{alias_name} for index #{index}"                                ; end
  end
  
  class UpdateIndexMapping < EsHttpOperation
    field :obj_type, String
    field :mapping,  Hash
    
    def path() File.join('', index, obj_type, '_mapping?')       ; end
    def body() { obj_type => mapping }                           ; end
    def verb() :put                                              ; end
    def info() "Updating #{obj_type} mapping for index #{index}" ; end
  end
  
  module Helpers
    def create_index_op(index, settings)
      CreateIndex.receive(index: index, settings: settings)
    end

    def update_settings_op(index, settings)
      UpdateIndexSettings.receive(index: index, settings: settings)
    end

    def delete_index_op(index, obj_type = nil)
      DeleteIndex.receive({ index: index, obj_type: obj_type }.compact_blank)
    end  

    def update_mapping_op(index, obj_type, mapping)
      UpdateIndexMapping.receive(index: index, obj_type: obj_type, mapping: mapping)
    end
    
    def alias_index_op (action, index, als, filter)
      AliasIndex.receive({ action: action, index: index, alias_name: als, filter: filter }.compact_blank)
    end    
  end
end
