module Wukong
  module Migrate
    class MigrateRunner < Wukong::Runner
      include Wukong::Logging
      include Wukong::Plugin ; log.level = 2
      
      description <<-DESC.gsub(/^ {8}/, '').strip
        Use this tool to create and perform database migrations using models
        defined in app/models. Options may be passed in as params on the commandline,
        else are discovered using Wukong::Deploy.settings

        $ wu-migrate generate schema_change --db=elasticsearch
        # Creates a template Elasticsearch migration file in db/migrate/schema_change.rb
 
        $ wu-migrate perform schema_change --db=elasticsearch
        # Interprets and runs the migration db/migrate/schema_change.rb

        $ wu-migrate all
        # Runs all migrations found in db/migrate

        Commands:

          generate <name> Creates a migration file for you under db/migrate/<name>
          perform  <name> Runs a specified migration
          all             Runs all migrations
      DESC
      
      class << self
        def configure(env, prog)
          env.define :debug, type: :boolean, default: false, description: 'Run in debug mode'
          env.define :db,    required: true,                 description: 'The database to apply the migration to'
          env.define :force, type: :boolean, default: false, description: 'Continue migrating through errors'
        end
      end

      def command
        args.first
      end
      
      def specified_migration
        args[1] or die('Must specify a migration when using this command', 1)
      end

      def migration_file_dir
        Wukong::Deploy.root.join('db/migrate')
      end

      def database_options
        opts = settings.to_hash
        opts.merge(opts.delete(settings.db.to_sym) || {})
      end

      def generate_migration_file(name, database)
        m_file = migration_file_dir.join(name + '.rb').to_s
        log.info "Creating migration: #{m_file}"
        case database
        when 'elasticsearch'
          File.open(m_file, 'w'){ |f| f.puts EsMigration.template(name) }
        when 'hbase'
          File.open(m_file, 'w'){ |f| f.puts HbaseMigration.template(name) }
        end
      end
      
      def load_all_migration_files!
        migration_file_dir.children.each do |m_file|
          Kernel.load m_file.to_s if m_file.extname == '.rb'
        end
      end
      
      def perform_migration(*names, options)
        names.each do |name|
          migration = Wukong::Migration.retrieve(name)
          migration.write_attribute(:log, self.log)
          migration.perform(options)
        end
      end
      
      def run
        case command
        when 'generate'
          generate_migration_file(specified_migration, settings.db)
        when 'perform'
          load_all_migration_files!
          perform_migration(specified_migration, database_options)
        when 'all'
          load_all_migration_files!
          perform_migration(*Wukong::Migration.all_migrations, database_options)
        else
          log.error "Please specify a valid command"
          dump_help_and_exit!
        end
      end

    end    
  end
end
