unless DB.table_exists?(:copies)
  DB.create_table :copies do
    primary_key :id
    String :url, :size=>2000, :null=>false #size of url
    String :sha1, :size=>40
    String :md5, :size=>40, :null=>false
    Bignum :size
    Time :timestamp
    foreign_key :aip_id, :aips, :type=>'integer', :null=>false
    index :aip_id, :name=>:index_copies_aip
  end
end

class Copy < Sequel::Model(:copies)
  plugin :validation_helpers
  def validate
    super
    validates_format %r([a-f0-9]{40}), :sha1
    validates_format %r([a-f0-9]{32}), :md5
    #validates_format /http/, :url
  end

  many_to_one :aip

  def download f
    rs = StorageMaster.new id, url.to_s
    rs.download f

    if size

      unless File.size(f) == self.size
        raise "#{url} size is wrong: expected #{size}, actual #{File.size(f)}"
      end

      actual_sha = Digest::SHA1.file(f).hexdigest
      unless actual_sha == self.sha1
        raise "#{url} sha1 is wrong: expected #{self.sha1}, actual #{actual_sha1}"
      end

    end

    actual_md5 = Digest::MD5.file(f).hexdigest
    unless actual_md5 == self.md5
      raise "#{url} md5 is wrong: expected #{self.md5}, actual #{actual_md5}"
    end

    f
  end

end

