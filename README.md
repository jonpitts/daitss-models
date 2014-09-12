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
   * Cannot assign multiple flags to property. Instead, each flag is treated as a property.
     * Forked repository and made modifications to handle multiple flag assignment.
     * https://github.com/jonpitts/sequel-bit_fields


