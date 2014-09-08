
Agent_Types = ["software", "person", "organization"]
Agent_Map = {
  "web service" => "software",
  "software" => "software",
  "affiliate" => "organization"
}

unless DB.table_exists? (:premis_agents)
  DB.create_table :premis_agents do
    String :id, :primary_key=>true, :type=>'varchar(255)'
    String :name, :size=>255
    String :type, :size=>20, :null=>false
    Text :note # additional agent note which may include external tool information
  end
end

class PremisAgent < Sequel::Model(:premis_agents)

  one_to_many :premis_events # :constraint => :destroy  # an agent can create 0-n events.

  # validate the agent type value which is a daitss defined controlled vocabulary
  def validateType
    unless Agent_Types.include?(@type)
      raise "value #{@type} is not a valid agent type value"
    end
  end

  def fromPremis premis
    self.id = premis.find_first("premis:agentIdentifier/premis:agentIdentifierValue", NAMESPACES).content
    self.name = premis.find_first("premis:agentName", NAMESPACES).content
    type = premis.find_first("premis:agentType", NAMESPACES).content
    self.type = Agent_Map[type.downcase]
    validateType
    note = premis.find_first("*[local-name()='agentNote']", NAMESPACES)
    self.note = note.content if note
  end

  def to_premis_xml
    # TODO agent note?
    agent :id => self.id, :name => self.name, :type => self.type
  end
end

