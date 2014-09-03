
unless DB.table_exists? (:broken_links)
  DB.create_table :broken_links do
    primary_key :id
    Text :broken_links # a "|" separated list of all broken links in the datafile <- this is before the new column "type" was added
    Text :type # can be one of:   stylesheet, dtd,  schema,  or unresolvable
    foreign_key :datafile_id, :datafiles, :null=>false, :type=>'varchar(100)', :on_update=>:cascade, :on_delete=>:cascade
    index :datafile_id, :name=>:index_broken_links_datafile
  end
end

class BrokenLink < Sequel::Model(:broken_links) 
 
 many_to_one :datafile # the associated Datafile
 
 def validate
   super
   puts "#{self.errors.to_a} error encountered while saving #{self.inspect} " unless valid?
 end

  def fromPremis(df, premis)
    # <eventOutcomeDetailExtension>  looks like:
    #  <eventOutcomeDetailExtension>
    #   <broken_link type="stylesheet">http://schema.fcla.edu/xml/broken-stylesheet-student_html.xsl</broken_link>
    #  </eventOutcomeDetailExtension>
    self.broken_links = premis.content
    self.type = premis['type']
    df.broken_links << self
  end

end
