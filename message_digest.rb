
  DIGEST_CODES = [
    "MD5", # MD5 message digest algorithm, 128 bits
    "SHA-1", # Secure Hash Algorithm 1, 160 bits
    "CRC32"
  ]

  ORIGINATOR = ["unknown", "archive", "depositor"]

  unless DB.table_exists? (:message_digests)
    DB.create_table :message_digests do
      primary_key :id
      String :code, :size=>10
      index :code, :name=>:index_message_digests_code
      String :value, :size=>255, :null=>false
      String :origin, :size=>10, :null=>false
      foreign_key :datafile_id, :datafiles, :type=>'varchar(100)', :null=>false, :on_update=>:cascade, :on_delete=>:cascade
      index :datafile_id, :name=>:index_message_digests_datafile
    end
  end

  class MessageDigest < Sequel::Model(:message_digests)

    many_to_one :datafile #, :key => true#, :unique_index => :u1  the associated Datafile

    def before_create
      super
      self.check_unique_code
    end
    
    def check_unique_code
      MessageDigest.first(:code => code, :datafile_id => datafile_id)
    end

    # validate the message digest code value which is a daitss defined controlled vocabulary
    def validateDigestCode
      unless DIGEST_CODES.include?(@code)
        raise "value #{@code} is not a valid message digest code value"
      end
    end

    def fromPremis(premis)
      code = premis.find_first("premis:messageDigestAlgorithm", NAMESPACES).content
      self.code = code
      validateDigestCode
      self.value = premis.find_first("premis:messageDigest", NAMESPACES).content
      origin = premis.find_first("premis:messageDigestOriginator", NAMESPACES)
      self.origin = origin.content.downcase if origin
    end
  end

