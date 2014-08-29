
unless DB.table_exists? (:sips)
  DB.create_table :sips do
    primary_key :id
    String :name, :size=>50, :null=>false
    Bignum :size_in_bytes
    Bignum :number_of_datafiles
    Bignum :submitted_datafiles
    foreign_key :package_id, :packages, :type=>'varchar(50)', :null=>false
    index :package_id, :name=>:index_sips_package
  end
end

# description of a submitted sip
class Sip < Sequel::Model(:sips)
  plugin :validation_helpers
  def validate
    super
    validates_presence :name
  end
  many_to_one :package
end