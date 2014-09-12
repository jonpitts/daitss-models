
# define arrays used for validating controlled vocabularies as defined in the textmd
Linebreaks = ["CR", "CR/LF", "LF"]
Text_Byte_Order = ["little", "big", "middle", "Unknown"]
Markup_Basis = ["SGML", "XML", "GML"]
Page_Order = ["left to right", "right to left"]
Line_Layout = ["right-to-left", "left-to-right", "top-to-bottom", "bottom-to-top"]
Line_Orientation = ["vertical", "horizontal"]

unless DB.table_exists? (:texts)
  DB.create_table :texts do
    primary_key :id
    String :charset, :size=>50 # character set employed by the text, see http://www.iana.org/assignments/character-sets
    String :byte_order, :size=>32, :null=>false, :default=>'Unknown'
    Integer :byte_size # the size of individual byte whtin the bits.
    String :linebreak, :size=>16 # how linebreaks are represented in the text
    String :language, :size=>128 # language used in the text, use ISO 639-2 codes.
    String :markup_basis, :size=>10 # The metalanguage used to create the markup language
    String :markup_language, :size=>255 # Markup language employed on the text (i.e., the specific schema or dtd).
    String :processing_note, :size=>255 # Any general note about the processing of the file
    String :page_order, :size=>32 # The natural page turning order of the text
    String :line_layout, :size=>32 # The arrangement of the page-level divs in the METS file.
    String :line_orientation, :size=>32 # The orientation of the lines on the page
    foreign_key :datafile_id, :datafiles, :type=>'varchar(100)', :on_update=>:cascade, :on_delete=>:cascade
    foreign_key :bitstream_id, :bitstreams, :type=>'varchar(100)', :on_update=>:cascade, :on_delete=>:cascade
  end
end

class Text < Sequel::Model(:texts)

  def fromPremis premis
    # extract characterset
    self.charset = premis.find_first("txt:character_info/txt:charset", NAMESPACES).content
    # extract and validate the byte_order
    byte_order = premis.find_first("txt:character_info/txt:byte_order", NAMESPACES)
    if byte_order
      self.byte_order = byte_order.content
      validate_byteorder
    end
    # extract and validate the byte_size      
    byte_size = premis.find_first("txt:character_info/txt:byte_size", NAMESPACES)
    self.byte_size = byte_size.content if byte_size
    # extract and validate the linebreak
    linebreak = premis.find_first("txt:character_info/txt:linebreak", NAMESPACES)
    if linebreak && !linebreak.content.empty?
      self.linebreak = linebreak.content
      validate_linebreak
    end
    # extract and validate the language 
    language = premis.find_first("txt:language", NAMESPACES)
    self.language = language.content if language
    # extract and validate the markup_basis 
    markup_basis = premis.find_first("txt:language/txt:markup_basis", NAMESPACES)
    if markup_basis
      self.markup_basis = markup_basis.content
      validate_markup_basis
    end
    # extract and validate the markup_language      
    markup_language = premis.find_first("txt:language/txt:markup_language", NAMESPACES)
    self.markup_language = markup_language.content if markup_language
    # extract and validate the processingNote       
    processing_note = premis.find_first("txt:language/txt:processingNote", NAMESPACES)
    self.processing_note = processing_note.content if processing_note
    # following are textmd 3.0 alpha elements
    # extract and validate the pageOrder       
    page_order = premis.find_first("txt:pageOrder", NAMESPACES)
    if page_order
      self.page_order = page_order.content
      validate_page_order
    end
    # extract and validate the lineLayout       
    line_layout = premis.find_first("txt:lineLayout", NAMESPACES)
    if line_layout
      self.line_layout = line_layout.content
      validate_line_layout
    end
    # extract and validate the lineOrientation       
    line_orientation = premis.find_first("txt:lineOrientation", NAMESPACES)
    if line_orientation
      self.line_orientation = line_orientation.content
      validate_line_orientation
    end
  end

  # validate the linebreak based on controlled vocabularies as defined in the textmd
  def validate_linebreak
    unless @linebreak.nil? || Linebreaks.include?(@linebreak)
      raise "value #{@linebreak} is not a valid linebreak value"
    end
  end

  # validate the byteorder based on controlled vocabularies as defined in the textmd
  def validate_byteorder
    unless Text_Byte_Order.include?(@byte_order)
      raise "value #{@byte_order} is not a valid text byte order"
    end
  end

  # validate the markup_basis based on controlled vocabularies as defined in the textmd
  def validate_markup_basis
    unless @markup_basis.nil? || Markup_Basis.include?(@markup_basis)
      raise "value #{@markup_basis} is not a valid markup_basis value" 
    end
  end

 # validate the page_order based on controlled vocabularies as defined in the textmd
  def validate_page_order
    unless @page_order.nil? || Page_Order.include?(@page_order)
      raise "value #{@page_order} is not a valid page_order value" 
    end
  end

 # validate the line_layout based on controlled vocabularies as defined in the textmd
  def validate_line_layout
    unless @line_layout.nil? || Line_Layout.include?(@line_layout)
      raise "value #{@line_layout} is not a valid line_layout value"
    end
  end

 # validate the line_orientation based on controlled vocabularies as defined in the textmd
  def validate_line_orientation
    unless @line_orientation.nil? || Line_Orientation.include?(@line_orientation)
      raise "value #{@line_orientation} is not a valid line_orientation value" 
    end
  end
  
end

