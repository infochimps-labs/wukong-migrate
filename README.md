# Wukong Migrate

A Wukong plugin that allows you to update database schema using predefined models from your deploy pack and a migration DSL.

## Commands

The following commands are available

### Generate

Creates a new migration file templated to match the chosen database. This command will create a new ruby file in `db/migrate` named after the argument supplied to `generate`. The only currently supported database is Elasticsearch, with future plans to support Hbase and others.

```
$ bundle exec wu-migrate generate change_schema --db=elasticsearch
# INFO 2013-07-29 14:14:51 [MigrateRunner       ] -- Creating migration: db/migrate/change_schema.rb
```

### Perform 

Performs the specified migration. This will talk to the database directly and apply the changes found in the migration. The tool will only perform migrations found in db/migrate, and specifying the `.rb` extension is not necessary. Currently, this is NOT an idempotent operation, and makes no guarantee of data safety on multiple invocations. Configuration is derived from command line parameters and through `Wukong::Deploy` settings.

```
$ bundle exec wu-migrate perform change_schema --db=elasticsearch
# INFO 2013-07-29 14:18:20 [MigrateRunner       ] -- Creating index jedi
# INFO 2013-07-29 14:18:21 [MigrateRunner       ] -- Operation complete
# INFO 2013-07-29 14:18:21 [MigrateRunner       ] -- Add alias :light_side for index jedi
# INFO 2013-07-29 14:18:21 [MigrateRunner       ] -- Operation complete
```

### All

Performs all available migrations in `db/migrate`. This is useful when setting up mirrored or development databases from existing migrations.

## Syntax

The following syntax is used to define migrations.

### Elasticsearch

All definitions take place inside of a `.define` block.

```ruby
EsMigration.define 'name_of_migration' do
...
end
```
Top-level methods are `create_index`, `update_index`, and `delete_index`. They can be used with or without block syntax.

```ruby
EsMigration.define 'name_of_migration' do
  create_index(:index_name) do
  ...
  end
  delete_index(:old_index)		   
end
```

Inside of an index block, you have access to mappings, aliases and index-level settings. Aliases are created/deleted one at a time and optionally accept filters. Mapping methods accept blocks for object-level settings.

```ruby
EsMigration.define 'name_of_migration' do
  create_index(:index_name) do
    number_of_replicas 4
    ...
    alias_to           :other_name, filter: { range: { date: { gt: '2013-05-05' } } }
    remove_alias       :prior_name
    create_mapping(:obj_type) do
      dynamic true
      source  false
      ...
    end			      
  end
  delete_index(:old_index)		   
end
```