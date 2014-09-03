
unless DB.table_exists?(:bitstreams)
  DB.create_table :bitstreams do
    String :id, :size=>100, :primary_key=>true, :null=>false
    Integer :size
    foreign_key :datafile_id, :datafiles, :type=>'varchar(100)', :null=>false, :on_update=>:cascade, :on_delete=>:cascade
    index :datafile_id, :name=>:index_bitstreams_datafile
  end
end

class Bitstream < Sequel::Model(:bitstreams)
  include Pobject
  
  many_to_one :datafile # a bitstream is belong to a datafile

  many_to_many :documents #:constraint => :destroy
  many_to_many :texts # :constraint => :destroy
  many_to_many :audios # :constraint => :destroy
  many_to_many :images # :constraint => :destroy

  many_to_many :object_formats # :constraint => :destroy # a bitstream may have 0-n formats

  def check_errors
    unless self.valid?
       bigmessage = self.errors.full_messages.join "\n" 
       raise bigmessage unless bigmessage.empty?
     end
               
    documents.each {|obj| obj.check_errors }       
     
    invalids = (texts).reject {|obj| obj.valid? }    
    bigmessage = invalids.map { |obj| obj.errors.full_messages.join "\n" }.join "\n"
    raise bigmessage unless bigmessage.empty?

    invalids = (audios ).reject {|obj| obj.valid? }    
    bigmessage = invalids.map { |obj| obj.errors.full_messages.join "\n" }.join "\n"
    raise bigmessage unless bigmessage.empty?

    invalids = (images ).reject {|obj| obj.valid? }    
    bigmessage = invalids.map { |obj| obj.errors.full_messages.join "\n" }.join "\n"
    raise bigmessage unless bigmessage.empty? 
  
    object_formats.each {|obj| obj.check_errors }               
  end
    
  def fromPremis(premis, formats)
    self.id = premis.find_first("premis:objectIdentifier/premis:objectIdentifierValue", NAMESPACES).content

    # process premis ObjectCharacteristicExtension
    node = premis.find_first("premis:objectCharacteristics/premis:objectCharacteristicsExtension", NAMESPACES)
    if (node)
      processObjectCharacteristicExtension(self, node)
      @object.datafile_id = nil
    end

    # process format information
    processFormats(self, premis, formats)
  end
end

