
unless DB.table_exists? (:report_deliveries)
  DB.create_table :report_deliveries do
    primary_key :id
    smallint :mechanism, :default=>1 #enum
    smallint :type, :default=>2 #enum
    foreign_key :package_id, :packages, :null=>false, :type=>'varchar(50)'
    index :package_id, :name=>:index_report_deliveries_package
  end
end

class ReportDelivery < Sequel::Model(:report_deliveries)
  #use sequel_enum plugin not pg_enum
  #pg_enum plugin is far too literal and too specific to postgres
  plugin :enum
  
  enum :mechanism, [:email, :ftp]
  enum :type, [:reject, :ingest, :disseminate]
  
  many_to_one :package
end
