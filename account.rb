
unless DB.table_exists? (:accounts)
  DB.create_table :accounts do
    String :id, :size=>50, :primary_key=>true
    Text :description
    String :report_email, :size=>50
  end
end

class Account < Sequel::Model(:accounts)
  one_to_many :projects
  one_to_many :agents
  
  def default_project
    p = self.projects.where(:id => Daitss::Archive::DEFAULT_PROJECT_ID).first
    
    unless p
      p = Project.new :id => Daitss::Archive::DEFAULT_PROJECT_ID, :account => self
      p.save
    end
    
    return p
  end
  
  # retrieve the list of user accounts, excluding the "SYSTEM" - system account used by DAITSS program
  def self.user_accounts
    Account.all - Account.where(:id => "SYSTEM")
  end
end
