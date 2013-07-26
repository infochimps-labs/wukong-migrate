module Gorillib
  module Builder
    
    def getset(field, *args, &block)
      ArgumentError.check_arity!(args, 0..1)
      if args.empty?
        read_attribute(field.name)
      else
        self.send("receive_#{field.name}", args.first)
      end
    end

    def getset_collection_item(field, item_key, attrs={}, &block)
      plural_name = field.plural_name
      if attrs.is_a?(field.item_type)
        # actual object: assign it into collection                                                                                                                          
        val = attrs
        set_collection_item(plural_name, item_key, val)
      elsif has_collection_item?(plural_name, item_key)
        # existing item: retrieve it, updating as directed                                                                                                    
        val = get_collection_item(plural_name, item_key)
        val.receive!(attrs, &block)
      else
        # missing item: autovivify item and add to collection                                                                                                               
        params = { key_method => item_key, :owner => self }.merge(attrs)
        val = self.send("receive_#{field.singular_name}", params, &block)
        set_collection_item(plural_name, item_key, val)
      end
      val
    end

    GetsetCollectionField.class_eval do
      def inscribe_methods model        
        raise "Plural and singular names must differ: #{self.plural_name}" if (singular_name == plural_name)
        #                                                                                                                                                                   
        @visibilities[:writer] = false
        model.__send__(:define_attribute_reader,   self.name, self.type, visibility(:reader))
        model.__send__(:define_attribute_tester,   self.name, self.type, visibility(:tester))
        #                                                                                                                                                                   
        model.__send__(:define_collection_receiver, self)
        model.__send__(:define_collection_getset,   self)
        model.__send__(:define_collection_tester,   self)
        #
        model.__send__(:define_collection_single_receiver, self)                                                                                                          
      end
    end
  end
  
  module Model

    ClassMethods.class_eval do
      def to_mapping
        { 
          properties: fields.inject({}) do |mapping, (name, field)|
            info = field.type.respond_to?(:to_mapping) ? field.type.to_mapping : field.to_mapping
            mapping[name] = info
            mapping
          end
        }
      end

      def define_collection_single_receiver field
        collection_single_field_name = field.singular_name
        field_type                   = field.item_type
        define_meta_module_method("receive_#{collection_single_field_name}", true) do |attrs, &block|
          begin
            field_type.receive(attrs, &block)
          rescue StandardError => err ; err.polish("#{self.class}.#{field_name} type #{type} on #{val}") rescue nil ; raise ; end
        end
      end
    end
    
    Field.class_eval do
      field :es_options, Hash

      def congruent?(klass, *others)
        others.any?{ |o| o.ancestors.include? klass }
      end
      
      def receive_as_type(factory, params)
        products = Array[factory.try(:product) || factory].flatten
        case 
        when congruent?(Integer, *products)
          EsInteger.receive(params)
        when congruent?(Float, *products)
          EsFloat.receive(params)
        when congruent?(Date, *products) || congruent?(Time, *products)
          EsDate.receive(params)
        when congruent?(TrueClass, *products) || congruent?(FalseClass, *products)
          EsBoolean.receive(params)
        when congruent?(Array, *products)
          receive_as_type(factory.items_factory, params)
        else
          EsString.receive(params)
        end
      end
      
      def to_mapping
        receive_as_type(type, es_options || {}).to_mapping
      end
    end
  end
end
