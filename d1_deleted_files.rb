module Daitss #used in daitss1 import. may be able to retire this as a module. needs testing
  
  unless DB.table_exists? (:d1deleted_files)
    DB.create_table :d1deleted_files do
      primary_key :id
      String :ieid, :size=>50 # daitss1 ieid
      index :ieid, :name=>:index_d1deleted_filed_ieid
      String :source, :size=>100 # the file which would be used to restore the duplicate.
      String :duplicate, :size=>100 # the duplicate file which was deleted in d1.
    end
  end

  class D1DeletedFile < Sequel::Model(:d1deleted_files)

  end
end
