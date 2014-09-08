
unless DB.table_exists? (:agents)
  DB.create_table :agents do
    String :id, :size=>50, :primary_key=>true
    Text :description
    String :auth_key, :size=>50
    String :salt, :size=>50, :null=>false
    String :type, :size=>50, :null=>false
    Time :deleted_at #ParanoidDateTime
    foreign_key :account_id, :accounts, :type=>'varchar(50)', :null=>false
    String :first_name, :size=>50
    String :last_name, :size=>50
    String :email, :size=>50
    String :phone, :size=>50
    Text :address
    TrueClass :is_admin_contact, :default=>false
    TrueClass :is_tech_contact, :default=>false
    Integer :permissions, :default=>0, :null=>false #bit field
  end
end

class Agent < Sequel::Model(:agents)
  plugin :validation_helpers
  plugin :single_table_inheritance, :type #Discriminator in DataMapper
  
  def before_create
    super
    self.salt ||= rand(0x100000).to_s 26
  end
  
  one_to_many :events
  one_to_many :requests
  one_to_many :comments

  many_to_one :account

  def encrypt_auth pass
    self.auth_key = Digest::SHA1.hexdigest("#{self.salt}:#{pass}")
  end

  def authenticate pass
    self.auth_key == Digest::SHA1.hexdigest("#{self.salt}:#{pass}") and self.deleted_at.nil?
  end

end

class User < Agent
  def validate
    super
    validates_format /@/, :email
  end

  def packages
    self.account.projects.packages
  end
  
end


class Contact < User
  #no Flag equivalent in sequel
  #property :permissions, Flag[:disseminate, :withdraw, :peek, :submit, :report]
  #use sequel-bit-fields plugin instead
  plugin :bit_fields, :permissions, [:disseminate, :withdraw, :peek, :submit, :report]
  
end

class Operator < User

  one_to_many :entries

  def packages
    Package.all
  end

end

class Service < Agent; end
class Program < Agent; end
