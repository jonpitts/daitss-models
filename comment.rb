
unless DB.table_exists? (:comments)
  DB.create_table :comments do
    primary_key :id
    Text :text, :null=>false
    DateTime :timestamp, :null=>false
    foreign_key :agent_id, :agents, :null=>false, :type=>'varchar(50)'
    foreign_key :event_id, :events, :null=>false
  end
end

class Comment < Sequel::Model(:comments)
  plugin :validation_helpers
  def before_create
    super
    self.timestamp = DateTime.now
  end
  
  def validate
    super
    validates_presence [:text, :timestamp]
  end

  many_to_one :agent
  many_to_one :event
end
