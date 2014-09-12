
# the relationship table only describe derivative relationship.  Whole-part relationship is denoted
# by the has and belongs_to associations.  Describing whole-part relationship using Relationship class
# is currently restricted to 1-to-1 derivative relationship.

# note: we may need relationships among representations, ex. shapefiles may be grouped into
# a reprensentation, and thus if the shapefiles representation is migrated to another collection
# of files, a relationship among representation would be needed. ** further analysis is needed.
Relationship_Type = ["migrated to", "normalized to", "include", "unknown"]
Relationship_Map = {
  "normalize" => "normalized to",
  "migrate" => "migrated_to"
}

unless DB.table_exists? (:relationships)
  DB.create_table :relationships do
    primary_key :id
    String :object1, :size=>100
    index :object1, :name=>:index_relationships_object1
    String :type, :size=>20, :null=>false
    String :object2, :size=>100
    index :object2, :name=>:index_relationships_object2
    foreign_key :premis_event_id, :premis_events, :type=>'varchar(100)', :on_update=>:cascade, :on_delete=>:cascade
  end
end

class Relationship < Sequel::Model(:relationships)

 many_to_one :premis_event
 self.raise_on_save_failure = false
 
  # validate the relationship type value which is a daitss defined controlled vocabulary
  def validateType
    unless Relationship_Type.include?(@type)
      raise "value #{@type} is not a valid relationship type value"
    end
  end

  def fromPremis(toObj, event_type, premis)
    self.object1 = premis.find_first("premis:relatedObjectIdentification/premis:relatedObjectIdentifierValue", NAMESPACES).content
    self.type = Relationship_Map[event_type]
    validateType
    self.object2 = toObj
    self.premis_event_id = premis.find_first("premis:relatedEventIdentification/premis:relatedEventIdentifierValue", NAMESPACES).content
  end
end
