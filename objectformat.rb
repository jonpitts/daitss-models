
# define arrays used for validating controlled vocabularies
PRIMARY = "primary"
SECONDARY = "secondary"
Object_Type = [PRIMARY, SECONDARY]

unless DB.table_exists? (:object_formats)
  DB.create_table :object_formats do
    primary_key :id
    String :type, :size=>10, :null=>false # indicate if format is the primary or secondary format for this data file
    String :note, :size=>50
    foreign_key :datafile_id, :datafiles, :type=>'varchar(100)', :on_update=>:cascade, :on_delete=>:cascade
    foreign_key :bitstream_id, :bitstreams, :type=>'varchar(100)', :on_update=>:cascade, :on_delete=>:cascade
    foreign_key :format_id, :formats, :type=>'integer', :null=>false
    index :format_id, :name=>:index_object_formats_format
  end
end

class ObjectFormat < Sequel::Model(:object_formats)

  many_to_one :format # the format of the datafile or bitstream.

  def setPrimary
    self.type = PRIMARY
  end

  def setSecondary
    self.type = SECONDARY
  end

  # check and dump any datamapper validation error.
  def check_errors
    unless valid? 
      bigmessage = self.errors.full_messages.join "\n" 
      raise bigmessage unless bigmessage.empty?
      
      raise "format should not be nil" if format.nil?
      raise "invalid format #{format}" unless format.valid?    
      raise "#{self.errors.to_a}, error encountered while saving #{@datafile_id}, #{@bitstream_id} " 
    end
  end
end

