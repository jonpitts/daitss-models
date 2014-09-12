
unless DB.table_exists? (:events)
  DB.create_table :events do
    primary_key :id
    String :name, :null=>false, :size=>50
    index :name, :name=>:index_events_name
    DateTime :timestamp, :null=>false
    Text :notes, :size=>2**32-1
    String :outcome, :size=>50, :default=>"N/A"
    foreign_key :agent_id, :agents, :type=>'varchar(50)', :null=>false
    index :agent_id, :name=>:index_events_agent
    foreign_key :package_id, :packages, :type=>'varchar(50)', :null=>false
    index :package_id, :name=>:index_events_package
  end
end

class Event < Sequel::Model(:events)
  plugin :validation_helpers
  self.raise_on_save_failure = false
  
  def valid
    super
    validates_presence [:name, :timestamp]
  end
  
  def before_create
    super
    self.timestamp = DateTime.now
  end
  
  many_to_one :agent
  many_to_one :package
  one_to_many :comments

  def polite_name
    if name =~ /unsnafu/
      name.gsub 'unsnafu', 'reset' 
    else
      name.gsub 'snafu', 'error'
    end
  end
end
