# DAITSS models
The purpose of this repository is to house new variants of daitss models.

Currently attemping to migrate daitss models from DataMapper to Sequel. 

## DataMapper

### Characteristics
 * Attributes and validations defined as properties in model

## Sequel

### Characteristics
 * Attributes defined in schema modifications:
   * create_table
 * Validations retained in model

### External Plugins Requirements
 * gem 'sequel_enum'
 * gem 'sequel-bit_fields'

