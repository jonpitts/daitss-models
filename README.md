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

### External Plugin Required
 * gem 'sequel_enum'
   * Behaves like dm-types plugin
 * gem 'sequel-bit_fields'
   * Behavior is different.
   * Cannot assign multiple flags to property. Instead, each flag is treated as a property.


