
# Please see mix 2.0 data dictionary for byte order values
Image_Byte_Order = ["big endian", "little endian", "Unknown"]

# Please see mix 2.0 data dictionary and NISO data in JHOVE for the compression scheme value
Compression_Scheme = ["Unknown", "Uncompressed", "CCITT 1D", "CCITT Group 3", "CCITT Group 4", "LZW", "JPEG",  "ISO JPEG",  "Deflate",
  "JBIG", "RLE with word alignment", "PackBits", "NeXT 2-bit encoding", "ThunderScan 4-bit encoding", "RasterPadding in CT or MP",
  "RLE for LW", "RLE for HC", "RLE for BL","Pixar 10-bit LZW",  "Pixar companded 11-bit ZIP encoding", "PKZIP-style Deflate encoding", "Kodak DCS",
  "SGI 32-bit Log Luminance encoding",  "SGI 24-bit Log Luminance encoding", "JPEG 2000" ]

# mapping of characterization output to MIX 2.0
Compression_Scheme_Map = {
  "uncompressed" => "Uncompressed",
  "Group 4 Fax" => "CCITT Group 4",
  "Group 3 Fax" => "CCITT Group 3"    
}

# Please see mix 2.0 data dictionary for the color space value
Color_Space = ["Unknown", "WhiteIsZero", "BlackIsZero", "RGB", "PaletteColor", "TransparencyMask", "CMYK",
  "YCbCr", "CIELab", "ICCLab", "DeviceGray", "DeviceRGB", "DeviceCMYK", "CalGray", "CalRGB",
  "Lab", "ICCBased", "Separation", "sRGB", "e-sRGB", "sYCC", "Indexed", "Pattern", "DeviceN",
  "YCCK", "Other" ]

# mapping of characterization output to MIX 2.0
Color_Space_Map = {
  "white is zero" => "WhiteIsZero",
  "black is zero" => "BlackIsZero",
  "palette color" => "PaletteColor",
  "transparency mask" => "TransparencyMask",
  "CIE L*a*b*" =>  "CIELab",
  "ICC L*a*b*" => "ICCLab",
  "ITU L*a*b*" => "Other",
  "CFA" => "Other",
  "CIE Log2(L)" => "Other",
  "CIE Log2(L)(u',v')" => "Other",
  "LinearRaw" => "Other"
}

Orientation = ["Unknown", "normal", "flipped", "rotated 180", "flipped rotated 180", "flipped rotated cw 90",
  "rotated ccw 90", "flipped rotated ccw 90", "rotated cw 90"]

# Please see mix 2.0 data dictionary for descriptions on sampling frequency
Sample_Frequency_Unit = ["no absolute unit of measurement", "inch", "centimeter"]
Sample_Frequency_Unit_Map = {
  "in." => "inch",
  "cm" => "centimeter"
}

Extra_Samples = ["unspecified data", "associated alpha data", "unassociated alpha data", "range or depth data"]

unless DB.table_exists? (:images)
  DB.create_table :images do
    primary_key :id
    String :byte_order, :size=>32, :null=>false, :default=>'Unknown' # byte order
    Integer :width # the width of the image, in pixels.
    Integer :height # the height of the image, in pixels.
    String :compression_scheme, :size=>64, :null=>false, :default=>'Unknown' # compression scheme used to store the image data
    String :color_space, :size=>64, :null=>false, :default=>'Unknown' # the color model of the decompressed image
    String :orientation, :size=>32, :null=>false, :default=>'Unknown' # orientation of the image, with respect to the placement of its width and height.
    String :sample_frequency_unit, :size=>64, :null=>false, :default=>'no absolute unit of measurement' # the unit of measurement for x and y sampling frequency
    Float :x_sampling_frequency # the number of pixels per sampling frequency unit in the image width
    Float :y_sampling_frequency # the number of pixels per sampling frequency unit in the image height
    String :bits_per_sample, :size=>255 # use value "1", "4", "8", "8,8,8", "8,2,2", "16,16,16", "8,8,8,8"]
    Integer :samples_per_pixel # the number of color components per pixel # positive int, TODO min = 0
    String :extra_samples, :size=>255, :null=>false, :default=>'unspecified data' # specifies that each pixel has M extra components whose interpretation is defined as above
    foreign_key :datafile_id, :datafiles, :type=>'varchar(100)', :on_update=>:cascade, :on_delete=>:cascade
    foreign_key :bitstream_id, :bitsteams, :type=>'varchar(100)', :on_update=>:cascade, :on_delete=>:cascade
  end
end

class Image < Sequel::Model(:images)
  def validate
    super
    errors.add(:width, 'cannot be negative') if width < 0
    errors.add(:height, 'cannot be negative') if height < 0
  end

  def validate_compression_scheme
    unless Compression_Scheme.include?(@compression_scheme)
      raise "value #{@compression_scheme} is not a valid image compression scheme"
    end
  end

  def validate_color_space
    unless Color_Space.include?(@color_space)
      raise "value #{@color_space} is not a valid image color space"
    end
  end

  def validate_orientation
    unless Orientation.include?(@orientation)
      raise "value #{@orientation} is not a valid image orientation"
    end
  end

  def validate_sample_frequency_unit
    unless Sample_Frequency_Unit.include?(@sample_frequency_unit)
      raise "value #{@sample_frequency_unit} is not a valid image sampling frequency unit" 
    end
  end

  def setDFID dfid
    self.datafile_id = dfid
  end

  def setBFID bfid
    self.bitstream_id = bfid
  end

  def fromPremis premis
    byte_order = premis.find_first("mix:BasicDigitalObjectInformation/mix:byteOrder", NAMESPACES)
    self.byte_order = byte_order.content if byte_order
    width = premis.find_first("mix:BasicImageInformation/mix:BasicImageCharacteristics/mix:imageWidth", NAMESPACES)
    self.width = width.content if width
    height = premis.find_first("mix:BasicImageInformation/mix:BasicImageCharacteristics/mix:imageHeight", NAMESPACES)
    self.height = height.content if height
    compressionScheme = premis.find_first("mix:BasicDigitalObjectInformation/mix:Compression/mix:compressionScheme", NAMESPACES)
    if compressionScheme
      if Compression_Scheme.include?(compressionScheme.content)
        self.compression_scheme = compressionScheme.content
      elsif Compression_Scheme_Map[compressionScheme.content]
        self.compression_scheme = Compression_Scheme_Map[compressionScheme.content]
      else
        raise "unrecognized compression scheme #{compressionScheme.content}"
      end
      validate_compression_scheme
    end
    
    colorspace = premis.find_first("mix:BasicImageInformation/mix:BasicImageCharacteristics/mix:PhotometricInterpretation/mix:colorSpace", NAMESPACES)
    if colorspace
      if Color_Space.include?(colorspace.content)
        self.color_space = colorspace.content
      elsif Color_Space_Map[colorspace.content]
        self.color_space = Color_Space_Map[colorspace.content]
      else
        raise "unrecognized color space #{colorspace.content}"
      end
      validate_color_space
    end
   
    # TODO: self.orientation = premis.find_first("mix:orientation", NAMESPACES).content
    # validate_orientation
    sfu = premis.find_first("mix:ImageAssessmentMetadata/mix:SpatialMetrics/mix:samplingFrequencyUnit", NAMESPACES)
    if sfu
      if Sample_Frequency_Unit.include?(sfu.content)
        self.sample_frequency_unit = sfu.content
      elsif Sample_Frequency_Unit_Map[sfu.content]
        self.sample_frequency_unit = Sample_Frequency_Unit_Map[sfu.content]
      else
        raise "unrecognized sampling frequency unit #{sfu.content}"
      end
      validate_sample_frequency_unit
    end

   
    xsf = premis.find_first("mix:ImageAssessmentMetadata/mix:SpatialMetrics/mix:xSamplingFrequency", NAMESPACES)
    unless xsf.nil?
      if xsf.find_first("mix:denominator", NAMESPACES)
        xsfv = xsf.find_first("mix:numerator", NAMESPACES).content.to_f / xsf.find_first("mix:denominator", NAMESPACES).content.to_f
      else
        xsfv = xsfv = xsf.find_first("mix:numerator", NAMESPACES).content.to_f
      end
      self.x_sampling_frequency = xsfv
    end

    ysf = premis.find_first("mix:ImageAssessmentMetadata/mix:SpatialMetrics/mix:ySamplingFrequency", NAMESPACES)
    unless ysf.nil?
      if ysf.find_first("mix:denominator", NAMESPACES)
        ysfv = ysf.find_first("mix:numerator", NAMESPACES).content.to_f / ysf.find_first("mix:denominator", NAMESPACES).content.to_f
      else
        ysfv = ysf.find_first("mix:numerator", NAMESPACES).content.to_f
      end
      self.y_sampling_frequency = ysfv
    end
    bpsv_list = premis.find("mix:ImageAssessmentMetadata/mix:ImageColorEncoding/mix:BitsPerSample/mix:bitsPerSampleValue", NAMESPACES)
    bps = Array.new
    bpsv_list.each {|value| bps << value.content}
    self.bits_per_sample = bps.join(",")
    bpsv_list = nil
    bps.clear
    bps = nil
    spp = premis.find_first("mix:ImageAssessmentMetadata/mix:ImageColorEncoding/mix:samplesPerPixel", NAMESPACES)
    self.samples_per_pixel = spp.content unless spp.nil?
    # TODO: self.extra_samples = premis.find_first("mix:extraSamples", NAMESPACES).content
  end

end

