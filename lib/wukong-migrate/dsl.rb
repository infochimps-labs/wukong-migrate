module Wukong
  module Migration

    Registry = {} unless defined? Registry

    class << self
      def all_migrations
        Registry.keys
      end
      
      def retrieve name
        Registry[name.to_s]
      end

      def register(name, migration)
        Registry[name.to_s] = migration
      end
    end

    class Dsl
      include Gorillib::Builder
      
      field :name, String
      field :log,  Whatever
      
      class << self
        def define(name, &operations)
          Wukong::Migration.register(name, self.new(&operations))
          true
        end
        
        def perform(options = {})
        end
      end
    end
  end
end
  
