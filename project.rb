
unless DB.table_exists? (:projects)
  DB.create_table :projects do
    String :id, :size=>50, :primary_key=>true
    Text :description
    foreign_key :account_id, :accounts, :type=>'varchar(50)', :null=>false, :on_update=>:cascade, :on_delete=>:cascade
  end
end

class Project < Sequel::Model(:projects)
  many_to_one :account
  one_to_many :packages
  
  def to_param
    id
  end
  
  def self.user_projects
    Project.all - Project.where(:account_id => "SYSTEM")
  end    
end
