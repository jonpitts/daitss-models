
unless DB.table_exists? (:datafile_severe_elements)
  DB.create_table :datafile_severe_elements do
    primary_key :id
    foreign_key :datafile_id, :datafiles, :type=>'varchar(100)', :on_update=>:cascade, :on_delete=>:cascade
    foreign_key :severe_element_id, :severe_elements, :null=>false, :type=>'integer'
    index :severe_element_id, :name=>:index_datafile_severe_elements_severe_element
  end
end

class DatafileSevereElement < Sequel::Model(:datafile_severe_elements)
  many_to_one :datafile
  many_to_one :severe_element
end

