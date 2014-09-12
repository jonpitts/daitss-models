
unless DB.table_exists? (:intentities)
  DB.create_table :intentities do
    String :id, :size=>50, :primary_key=>true
    # daitss1 ieid
    String :original_name, :size=>32, :null=>false, :default=>'UNKNOWN'
    # i.e. package_name
    String :entity_id, :size=>100
    String :volume, :size=>64
    String :issue, :size=>64
    Text :title
    foreign_key :package_id, :packages, :type=>'varchar(50)', :null=>false
    index :package_id, :name=>:index_intentities_package
  end
end

class Intentity < Sequel::Model(:intentities)
  plugin :validation_helpers

  many_to_one :package
  one_to_many :datafiles, :constraint=>:destroy
  
  self.raise_on_save_failure = false

  def check_errors
    unless self.valid?
      bigmessage = self.errors.full_messages.join "\n" 
      raise bigmessage unless bigmessage.empty?
    end
    
    unless package.valid?
      bigmessage = package.errors.full_messages.join "\n" 
      raise bigmessage unless bigmessage.empty?
    end
        
    datafiles.each {|df| df.check_errors }    
  end
  
  # construct an int entity with the information from the aip descriptor
  def fromAIP aip
    entity = aip.find_first('//p2:object[p2:objectCategory="intellectual entity"]', NAMESPACES)
    raise "cannot find required intellectual entity object in the aip descriptor" if entity.nil?
    # extract and set int entity id
    id = entity.find_first("p2:objectIdentifier/p2:objectIdentifierValue", NAMESPACES)
    raise "cannot find required objectIdentifierValue for the intellectual entity object in the aip descriptor" if id.nil?
    attribute_set(:id, id.content)

    originalName = entity.find_first("p2:originalName", NAMESPACES)
    attribute_set(:original_name, originalName.content) if originalName

    # extract and set the rest of int entity metadata
    mods = aip.find_first('//mods:mods', NAMESPACES)
    if mods
      title = mods.find_first("mods:titleInfo/mods:title", NAMESPACES)
      attribute_set(:title, title.content) if title
      volume = mods.find_first("mods:part/mods:detail[@type = 'volume']/mods:number", NAMESPACES)
      attribute_set(:volume, volume.content) if volume
      issue = mods.find_first("mods:part/mods:detail[@type = 'issue']/mods:number", NAMESPACES)
      attribute_set(:issue, issue.content) if issue
      entityid = mods.find_first("mods:identifier[@type = 'entity id']", NAMESPACES)
      attribute_set(:entity_id, entityid.content) if entityid
    end
  end

  # delete this datafile record and all its children from the database
  def deleteChildren
    # find the id of all datafiles belong to this int entity
    datafiles = Datafiles.where(:intentity_id=>@id)
    dfs.each do |df|
      # delete all related premis_events records and its associated relationships which will be deleted
      # automatically by cascade delete
      PremisEvent.where(:related_object_id=>df.id).delete
    end
    # delete all events associated with this int entity
    PremisEvent.where(:related_object_id=>@id).delete
  end

  def match id
    matched = false
    if id && id == @id
      matched = true
    end
    matched
  end

end

