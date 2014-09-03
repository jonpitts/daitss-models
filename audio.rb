
  # byte order values as defined in aes
  Audio_Byte_Order = ["BIG_ENDIAN", "LITTLE_ENDIAN", "Unknown"]
  
  unless DB.table_exists? (:audios)
    DB.create_table :audios do
      primary_key :id
      String :byte_order, :null=>false, :size=>32, :default=>'Unknown'
      String :encoding, :size=>255 # the audio encoding scheme
      Float :sampling_frequency # the number of audio samples that are recorded per second (in Hertz, i.e. cycles per second)
      Integer :bit_depth # the number of bits used each sample to represent the audio signal
      Integer :channels # the number of channels that are part of the audio stream
      Integer :duration # the length of the audio recording, described in seconds
      String :channel_map, :size=>64  # channel mapping, mono, stereo, etc, TBD
      foreign_key :datafile_id, :datafiles, :type=>'varchar(100)', :on_update=>:cascade, :on_delete=>:cascade
      foreign_key :bitstream_id, :bitstreams, :type=>'varchar(100)', :on_update=>:cascade, :on_delete=>:cascade
    end
  end

  class Audio < Sequel::Model(:audios)

    # validate the audio byte order value which is a daitss defined controlled vocabulary
    def validateByteOrder
      unless Audio_Byte_Order.include?(@byte_order)
        raise "value #{@byte_order} is not a valid byte_order value"
      end
    end

    def setDFID dfid
      self.datafile_id = dfid
    end

    def setBFID bsid
      self.bitstream_id = bsid
    end

    def fromPremis premis
      byte_order = premis.find_first("aes:byte_order", NAMESPACES)
      if byte_order
        self.byte_order = byte_order.content
        validateByteOrder
      end
      self.encoding = premis.find_first("aes:audioDataEncoding", NAMESPACES).content
      self.sampling_frequency = premis.find_first("aes:formatList/aes:formatRegion/aes:sampleRate", NAMESPACES).content
      self.bit_depth = premis.find_first("aes:formatList/aes:formatRegion/aes:bitDepth", NAMESPACES).content
      self.channels = premis.find_first("aes:face/aes:region/aes:numChannels", NAMESPACES).content

      # calculate the duration in number of seconds, make sure timeline/duration exist
      if premis.find_first("aes:face/aes:timeline/tcf:duration")
        hours = premis.find_first("aes:face/aes:timeline/tcf:duration/tcf:hours", NAMESPACES).content
        minutes = premis.find_first("aes:face/aes:timeline/tcf:duration/tcf:minutes", NAMESPACES).content
        seconds = premis.find_first("aes:face/aes:timeline/tcf:duration/tcf:seconds", NAMESPACES).content
        durationInS = seconds.to_i + minutes.to_i * 60 + hours.to_i * 3600
        self.duration = durationInS
      end

      if node = premis.find_first("//@mapLocation", NAMESPACES)
        # NOISE
        # puts node.inspect
        channelMap = node.value
        self.channel_map = channelMap
      end
    end

  end

