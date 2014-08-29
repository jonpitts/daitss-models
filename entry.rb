
unless DB.table_exists? (:entries)
  DB.create_table :entries do
    primary_key :id
    DateTime :timestamp, :null=>false
    Text :message, :null=>false
    foreign_key :operator_id, :agents, :null=>false, :type=>'varchar(50)'
  end
end

# represents an admin log entry
class Entry < Sequel::Model(:entries)
  def before_create
    super
    self.timestamp = DateTime.now
  end

  many_to_one :agent #operator
end
