
unless DB.table_exists? (:batches)
  DB.create_table :batches do
    String :id, :size=>50, :primary_key=>true
  end
end

class Batch < Sequel::Model(:batches)
  one_to_many :batch_assignments
  many_to_many :packages, :join_table => :batch_assignments # has_many :packages, :through=>:batch_assignments
end

unless DB.table_exists? (:batch_assignments)
  DB.create_table :batch_assignments do
    foreign_key :batch_id, :batches, :type=>'varchar(50)', :null=>false
    foreign_key :package_id, :packages,:type=>'varchar(50)', :null=>false
    primary_key [:batch_id, :package_id]
    index :batch_id, :name=>:index_batch_assignments_batch
    index :package_id, :name=>:index_batch_assignments_package
  end
end

class BatchAssignment < Sequel::Model(:batch_assignments)
  many_to_one :batch
  many_to_one :package
end