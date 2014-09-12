
unless DB.table_exists? (:severe_elements)
  DB.create_table :severe_elements do
    primary_key :id
    String :name, :size=>255 # the name of the severe element
    index :name, :name=>:index_severe_elements_name
    String :class, :size=>50, :null=>false #single_table_inheritance
    String :target, :size=>255 # the target of this inhibitor
    String :ikey, :size=>255 # the key to resolve the inhibitor
  end
end

class SevereElement < Sequel::Model(:severe_elements)
  plugin :single_table_inheritance, :type
  one_to_many :datafile_severe_element

end

class Inhibitor < SevereElement
  def fromPremis(premis)
    self.name = premis.find_first("premis:inhibitorType", NAMESPACES).content
    node = premis.find_first("premis:inhibitorTarget", NAMESPACES)
    self.target = node.content unless node.nil?
    node = premis.find_first("premis:inhibitorKey", NAMESPACES)
    self.ikey = node.content unless node.nil?
  end
end

# for certain anomaly, JHOVE outputs tons of variation for the same kind of anomaly, e.g.
#"Value offset not word-aligned : 644", "Value offset not word-aligned : 1250", etc.  This is
# the set to combine those anomalies into a simplied one.
# To Do: finish the conversion.
TRIM_ANOMALY = [
  "Value offset not word-aligned",
  "Unknown TIFF IFD tag",
  "Flash value out of range",
  "Invalid DateTime length",
  "Type mismatch for tag",
  "Invalid DateTime separator",
  "out of sequence",
  "cvc-id.2: There are multiple occurrences of ID value"
]

class Anomaly < SevereElement
  def fromPremis(premis)
    # truncate the anomaly name over 255 characters
    truncated = premis.content.slice(0, 255)
    TRIM_ANOMALY.each {|a| truncated = a if truncated.include? a}
    self.name = truncated
  end
end

