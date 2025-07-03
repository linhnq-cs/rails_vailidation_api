# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Testing
- `ruby runtest.rb` - Run the test example that validates a sample input against defined rules

### Gem Management
- `gem build rails_validation.gemspec` - Build the gem locally
- `gem install rails_validation-*.gem` - Install the gem locally after building

### Generator Commands
- `rails_validation install` - Install the gem and generate application validator
- `rails_validation generate [name]` - Generate both parameter and regular validators for a given name
- `rails_validation destroy [name]` - Remove validators for a given name

## Architecture Overview

This is a Ruby gem that provides Rails-style parameter validation using a DSL approach. The gem extends the `rails_param` gem to provide automatic validation through Rails controller concerns.

### Core Components

**Main Entry Point**: `lib/rails_validation.rb`
- Defines the main `RailsValidation` module and `Error` class
- Provides `RailsValidation.build` method for DSL-based rule definition

**Validator Engine**: `lib/rails_validation/validator.rb`
- `RailsValidation::Validator` class handles parameter validation
- Includes `RailsParam::Param` for validation logic
- Supports nested validation for Hash/Array fields
- Collects errors and raises `RailsValidation::Error` with field context

**DSL Builder**: `lib/rails_validation/dsl.rb`
- `RailsValidation::DSL` class provides `param!` method for rule definition
- Supports nested validation rules through block syntax

**Auto-Loading Concern**: `lib/auto_load_rails_validation.rb`
- `AutoLoadRailsValidation` module provides Rails controller integration
- Automatically loads validators based on controller/action names
- Expects validators in `API::ValidateParameters::*Validator` and `API::*Validator` patterns

### Generated Validator Structure

The gem generates validators in two locations:
- Parameter validators: `app/validators/api/validate_parameters/[name]_validator.rb`
- Business logic validators: `app/validators/api/[name]_validator.rb`

Parameter validators define `FIELDS_VALIDATES` hash with validation rules and action methods that return relevant rules.

### Dependencies

- `rails_param` (~> 0.9.0) - Core parameter validation logic
- `activesupport` (>= 6.0) - For Rails utilities and concerns
- `activemodel` (>= 6.0) - For model validation features

## Key Files

- `runtest.rb` - Test script demonstrating validation usage
- `exe/rails_validation` - Command-line generator tool
- `lib/rails_validation/version.rb` - Version management