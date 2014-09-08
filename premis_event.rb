
# constant for event types
INGEST = "ingest"
SUBMIT = "submit"
VALIDATE = "validate"
VIRUS_CHECK = "virus check"
DISSEMINATE = "disseminate"
REFRESH = "refresh"  
D1REFRESH = "d1refresh"
REDUP = "redup"
WITHDRAW = "withdraw"
FIXITY_CHECK = "fixitycheck"
DESCRIBE = "describe"
NORMALIZE = "normalize"
MIGRATE = "migrate"
XML_RESOLUTION = "xml resolution"
DELETION = "deletion"
BROKEN_LINKS = "broken links found"

# all possible event types
Event_Type = [INGEST, SUBMIT, VALIDATE, VIRUS_CHECK, DISSEMINATE, REFRESH, D1REFRESH, REDUP,
  WITHDRAW, FIXITY_CHECK, DESCRIBE, NORMALIZE, MIGRATE, XML_RESOLUTION, DELETION, BROKEN_LINKS]

Event_Map = {
  "ingest" => INGEST,
  "submit" => SUBMIT,
  "comprehensive validation" => VALIDATE,
  "virus check" => VIRUS_CHECK,
  "disseminate" => DISSEMINATE,
  "refresh" => REFRESH,    
  "d1refresh" => D1REFRESH,
  "redup" => REDUP,
  "withdraw" => WITHDRAW,
  "fixity Check" => FIXITY_CHECK,
  "describe" => DESCRIBE,
  "normalize" => NORMALIZE,
  "migration" => MIGRATE,
  "xml resolution" => XML_RESOLUTION,
  "broken links found" => BROKEN_LINKS,
}

unless DB.table_exists? (:premis_events)
  DB.create_table :premis_events do
    String :id, :primary_key=>true, :type=>'varchar(100)'
    String :idType, :name=>:id_type, :size=>50
    String :e_type, :size=>20, :null=>false
    DateTime :datetime
    String :event_detail, :size=>255 # event detail
    String :outcome, :size=>255 # ex. sucess, failed.  TODO:change to Enum.
    Text :outcome_details # additional information about the event outcome.
    String :relatedObjectId, :name=>:related_object_id, :size=>100 # the identifier of the related object.
    index :related_object_id, :name=>:index_premis_events_related_object_id # if object A migrated to object B, the object B will be associated with a migrated_from event
    String :class, :size=>50, :null=>false
    foreign_key :premis_agent_id, :premis_agents, :type=>'varchar(255)', :null=>false, :on_update=>:cascade, :on_delete=>:cascade
    index :premis_agent_id, :name=>:index_premis_events_premis_agent
  end
  #DB.run "create index index_ieid on premis_events(substring(premis_events.related_object_id from'................$'))" #does not work in sqlite
  #sqlite equivalent => substr(related_object_id,-16)
end

class PremisEvent < Sequel::Model(:premis_events)
  plugin :single_table_inheritance, :class

  many_to_one :premis_agent
  # an event must be associated with an agent
  # note: for deletion event, the agent would be reingest.

  # datamapper return system error once this constraint is added in (#<SystemStackError: stack level too deep>).  
  # so we will add cascade delete on postgres directly. 
  # has 0..n, :relationships, :constraint=>:destroy

  # validate the event type value which is a daitss defined controlled vocabulary
  def validateEventType
    unless Event_Type.include?(@e_type)
      raise "value #{@e_type} is not a valid event type value"
    end
  end

  # set related object id which could either be a datafile or an intentity object
  def setRelatedObject objid
    self.relatedObjectId = objid
  end

  def fromPremis(premis)
    self.id = premis.find_first("premis:eventIdentifier/premis:eventIdentifierValue", NAMESPACES).content
    self.idType = premis.find_first("premis:eventIdentifier/premis:eventIdentifierType", NAMESPACES).content
    type = premis.find_first("premis:eventType", NAMESPACES).content
    self.e_type = Event_Map[type.downcase]
    validateEventType
    eventDetail = premis.find_first("premis:eventDetail", NAMESPACES)
    self.event_detail = eventDetail.content if eventDetail
    self.datetime = premis.find_first("premis:eventDateTime", NAMESPACES).content
    self.outcome = premis.find_first("premis:eventOutcomeInformation/premis:eventOutcome", NAMESPACES).content
    detailExtension = premis.find_first("premis:eventOutcomeInformation/premis:eventOutcomeDetail/premis:eventOutcomeDetailExtension", NAMESPACES)
    self.outcome_details = detailExtension.children.join  unless detailExtension.nil?
  end

  def to_premis_xml
     event :id => self.id, :type => self.e_type, :time => self.datetime, :outcome => self.outcome, :linking_agents => [self.premis_agent.id], :linking_objects => [self.relatedObjectId]
   end

end

class IntentityEvent < PremisEvent
end

class RepresentationEvent < PremisEvent
end

class DatafileEvent < PremisEvent
  attr_reader :df
  attr_reader :anomalies

  def fromPremis(premis, df, anomalies)
    super(premis)
    details = premis.find_first("premis:eventOutcomeInformation/premis:eventOutcomeDetail", NAMESPACES)
    if details
      detailsExtension = details.find_first("premis:eventOutcomeDetailExtension", NAMESPACES)
      unless detailsExtension.nil?
        @df = df
        @anomalies = anomalies
        nodes = detailsExtension.find("premis:anomaly", NAMESPACES)
        processAnomalies(nodes)
        nodes = detailsExtension.find("premis:broken_link", NAMESPACES)
        unless (nodes.empty?)
          children = detailsExtension.children
            children.each do |child|
            brokenlink = BrokenLink.new
            brokenlink.fromPremis(@df, child)
          end
        end
      end
    end
  end

  def processAnomalies(nodes)
    nodes.each do |obj|
      anomaly = Anomaly.new
      anomaly.fromPremis(obj)

      # check if it was processed earlier.
      existinganomaly = @anomalies[anomaly.name]

      # if it's has not processed earlier, use the existing anomaly record
      # in the database if we have seen this anomaly before
      existinganomaly = Anomaly.first(:name => anomaly.name) if existinganomaly.nil?
      dfse = DatafileSevereElement.new
      @df.datafile_severe_element << dfse
      if existinganomaly
        existinganomaly.datafile_severe_element << dfse
      else
        anomaly.datafile_severe_element << dfse
        @anomalies[anomaly.name] = anomaly
      end
    end
  end

end

