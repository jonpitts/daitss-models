

  FEATURES = {
    "hasOutline" => :hasOutline,
    "isTagged" => :isTagged,
    "hasThumbnails" => :hasThumbnails,
    "hasAnnotations" => :hasAnnotations
  }
  
  unless DB.table_exists? (:documents)
    DB.create_table :documents do
      primary_key :id
      Integer :pageCount, :name=>:page_count # total number of pages in the document
      Integer :wordCount, :name=>:word_count # total number of words in the document
      Integer :characterCount, :name=>:character_count # total number of characters in the document
      Integer :paragraphCount, :name=>:paragraph_count # total number of paragraphs in the document
      Integer :lineCount, :name=>:line_count # total number of lines in the document
      Integer :tableCount, :name=>:table_count # total number of tables in the document
      Integer :graphicsCount, :name=>:graphics_count # total number of graphics in the document
      String :language, :size=>128  # the natural language used in the document (language code)
      Integer :features #bit field
      foreign_key :datafile_id, :datafiles, :type=>'varchar(100)', :on_update=>:cascade, :on_delete=>:cascade
      foreign_key :bitstream_id, :bitstreams, :type=>'varchar(100)', :on_update=>:cascade, :on_delete=>:cascade
    end
  end

  class Document < Sequel::Model(:documents)
    plugin :bit_fields, :features, [:isTagged, :hasOutline, :hasThumbnails, :hasLayers, :hasForms, :hasAnnotations, :hasAttachments, :useTransparency]
    # additional document features.
    one_to_many :fonts

    def fromPremis premis
      self.pageCount = premis.find_first("doc:PageCount", NAMESPACES).content.to_i
      lang = premis.find_first("doc:Language", NAMESPACES)
      self.language = lang.content unless lang.nil

      # set all features associated with this document
      nodes = premis.find("doc:Features", NAMESPACES)
      nodes.each do |node|
        self.features = FEATURES[node.content]
      end

      # extract all fonts encoded in the document
      nodes = premis.find("doc:Font", NAMESPACES)
      nodes.each do |node|
        font = Font.new
        font.fromPremis node
        fonts << font
      end
    end

    def check_errors
      raise self.errors.full_messages.join "\n" unless valid?
      
      fonts.each do |obj| 
        obj.errors.full_messages.join "\n" unless obj.valid?
      end
    end

  end
  
  unless DB.table_exists? (:fonts)
    DB.create_table :fonts do
      primary_key :id
      String :fontname, :size=>255 # the name of the font
      TrueClass :embedded # where or not the font is embedded in the document
      foreign_key :document_id, :documents, :null=>false, :type=>'integer', :on_update=>:cascade, :on_delete=>:cascade
      index :document_id, :name=>:index_fonts_document
    end
  end

  class Font < Sequel::Model(:fonts)

    many_to_one :document

    def fromPremis premis
      self.fontname = premis.find_first("@FontName", NAMESPACES).value
      self.embedded = premis.find_first("@isEmbedded", NAMESPACES).value
    end

  end

