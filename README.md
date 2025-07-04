# Rails Validation API

Enhanced parameter validation system for Rails APIs with automatic controller integration.

Rails Validation API provides a powerful DSL for validating request parameters in Rails applications. Features include automatic validator loading based on controller/action names, nested parameter validation, custom error handling, and seamless integration with Rails controllers through concerns. Perfect for API applications requiring robust parameter validation with minimal boilerplate code.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rails_validation_api'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install rails_validation_api
```

## Usage

### Initial Setup

After installing the gem, run the install command to set up the necessary files:

This will generate the required application validator structure in your Rails application.

### Basic Usage

The gem provides automatic parameter validation through Rails controller concerns. It automatically loads validators based on controller and action names.

#### Example Controller

```ruby
class API::UsersController < ApplicationController
  include AutoLoadRailsValidation

  def create
    # Parameters are automatically validated using API::ValidateParameters::UsersValidator
    # and API::UsersValidator (if they exist)
    
    # Your controller logic here
    render json: { message: "User created successfully" }
  end
end
```

#### Example Validator

```ruby
# app/validators/api/validate_parameters/users_validator.rb
class API::ValidateParameters::UsersValidator
  FIELDS_VALIDATES = {
    name: { required: true, type: String },
    email: { required: true, type: String, format: /@/ },
    age: { required: false, type: Integer, min: 18 }
  }

  def create
    FIELDS_VALIDATES.slice(:name, :email, :age)
  end

  def update
    FIELDS_VALIDATES.slice(:name, :email)
  end
end
```

## Commands

### Generate Validators

Generate both parameter and business logic validators for a given name:

```bash
bundle exec rails_validation_api generate users
```

This creates:
- `app/validators/api/validate_parameters/users_validator.rb` - Parameter validation
- `app/validators/api/users_validator.rb` - Business logic validation

### Destroy Validators

Remove validators for a given name:

```bash
bundle exec rails_validation_api destroy users
```

This removes both parameter and business logic validators.

## Validation DSL

The gem uses a DSL approach for defining validation rules:

```ruby
# Using RailsValidation.build
validator = RailsValidation.build do
  param! :name, String, required: true
  param! :email, String, required: true, format: /@/
  param! :profile do
    param! :age, Integer, required: false, min: 18
    param! :city, String, required: true
  end
end

# Validate parameters
begin
  validator.validate(params)
rescue RailsValidation::Error => e
  render json: { errors: e.message }, status: 422
end
```

## Features

- **Automatic Loading**: Validators are automatically loaded based on controller/action names
- **Nested Validation**: Support for validating nested Hash/Array parameters
- **Custom Error Handling**: Detailed error messages with field context
- **Rails Integration**: Seamless integration through Rails controller concerns
- **DSL Support**: Flexible DSL for defining validation rules
- **Generator Commands**: Easy validator generation and management

## Development

### Testing

Run the test example:

```bash
ruby runtest.rb
```

### Building the Gem

```bash
gem build rails_validation_api.gemspec
gem install rails_validation_api-*.gem
```

## Dependencies

- `rails_param` (~> 0.9.0) - Core parameter validation logic
- `activesupport` (>= 6.0) - For Rails utilities and concerns
- `activemodel` (>= 6.0) - For model validation features

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/linhnq-cs/rails_vailidation_api.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
