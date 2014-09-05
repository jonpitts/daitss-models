
DEFAULT_REGISTRY = "http://www.fda.fcla.edu/format"

unless DB.table_exists? (:formats)
  DB.create_table :formats do
    primary_key :id
    String :registry, :size=>50 # the namespace of the format registry, ex:http://www.nationalarchives.gov.uk/pronom
    String :registry_id, :size=>50 # the format identifier in the registry, ex: fmt/10
    String :format_name, :size=>255 # common format name, ex:  "TIFF"
    index :format_name, :name=>:index_formats_format_name
    String :format_version, :size=>50 # format version,  ex: "5.0"
  end
end

class Format < Sequel::Model(:formats)

  one_to_many :object_formats

  def fromPremis premis
    self.format_name = premis.find_first("premis:formatDesignation/premis:formatName", NAMESPACES).content
    if premis.find_first("premis:formatDesignation/premis:formatVersion", NAMESPACES)
      self.format_version = premis.find_first("premis:formatDesignation/premis:formatVersion", NAMESPACES).content
    end

    if premis.find_first("premis:formatRegistry", NAMESPACES)
      self.registry = premis.find_first("premis:formatRegistry/premis:formatRegistryName", NAMESPACES).content
      self.registry_id = premis.find_first("premis:formatRegistry/premis:formatRegistryKey", NAMESPACES).content
    end
  end

end

