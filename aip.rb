
require 'libxml'
require 'net/http'

include LibXML
XML.default_line_numbers = true
XML_SIZE = 2**32-1
XML_ERRATA_SIZE = 65535

unless DB.table_exists? (:aips)
  DB.create_table :aips do
    primary_key :id
    Text :xml, :null=>false
    Text :xml_errata
    Integer :datafile_count
    foreign_key :package_id, :packages, :null=>false, :type=>'varchar(50)'
  end
end

class Aip < Sequel::Model(:aips)
  plugin :validation_helpers
  self.raise_on_save_failure = false
  def validate
    super
    validates_presence :xml
    validates_max_length XML_SIZE, :xml
    validates_max_length XML_ERRATA_SIZE, :xml_errata
  end

  many_to_one :package
  one_to_one :copy # 0 if package has been withdrawn, otherwise, 1

  # report error upon failure in saving 
  def check_errors
    unless self.valid?
      bigmessage = self.errors.full_messages.join "\n" 
      raise bigmessage unless bigmessage.empty?
    end
    
    unless copy.valid?
      bigmessage =  copy.errors.full_messages.join "\n" 
      raise bigmessage unless bigmessage.empty?
    end
  end
 
  # save to database
  def toDB
    @xml_errata = @xml_errata.slice(0, XML_ERRATA_SIZE) if @xml_errata
    unless self.save
      self.check_errors 
      raise "error in saving Aip record, no validation error found"
    end
  end

end

