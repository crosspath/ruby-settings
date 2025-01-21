# Settings

The fastest solution for reading settings from configuration files (YAML, JSON), because it's based on Struct.

You may store configuration files in any directory and name them whatever you want!

Supported file extensions:

* `.yml, `.yaml` for YAML files
* `.json` for JSON files

Example:

```ruby
# If you put this file into config/initializers and you want to use configuration files from
# config/settings:

AppConfig =
  Settings.configurate do
    # Read all matching files (config/settings/*.yaml).
    files("#{__dir__}/../settings/*.yaml")

    # Read only specified file (example: config/settings/production.json).
    file("#{__dir__}/../settings/#{Rails.env}.json")
  end

# Read and write config values:
puts AppConfig.parent_group.field_name
AppConfig.parent_group.field_name = 1
```

Config values can be modified after initialization. You may use this feature for testing your application objects when their behaviour depends on this configuration.

Of course, you may use this gem for global configuration (as in initializer) or for limited scope (in this case you have to define initialization of `Settings.configurate` and a place for it in your application).

## Development

Before release — apply suggestions from RuboCop, review them and commit or reject:

```shell
bin/rubocop --autofix
```

Try your gem locally, then commit changes in local repository.

Push new version to remote repository:

```shell
bin/release
```
