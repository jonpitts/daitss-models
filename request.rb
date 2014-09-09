RequestStatus = [:enqueued, :released_to_workspace, :cancelled]
RequestTypes = [:disseminate, :withdraw, :refresh, :peek]

unless DB.table_exists? (:requests)
  DB.create_table :requests do
    primary_key :id
    Text :note
    DateTime :timestamp, :null=>false
    TrueClass :is_authorized, :null=>false, :default=>true
    Integer :status, :default=>0, :null=>false #bit_field plugin requires default 0 and null false
    Integer :type, :default=>0, :null=>false
    foreign_key :agent_id, :agents, :null=>false, :type=>'varchar(50)'
    index :agent_id, :name=>:index_requests_agent
    foreign_key :package_id, :packages, :null=>false, :type=>'varchar(50)'
    index :package_id, :name=>:index_requests_package
  end
end

class Request < Sequel::Model(:requests)
  plugin :bit_fields, :status, RequestStatus
  plugin :bit_fields, :type, RequestTypes
  
  def before_create
    super
    self.timestamp = DateTime.now
    self.enqueued = true
  end
  
  #convenience method to assign multiple status flags
  def status= args 
    args = [args] unless args.is_a? Array
    args.each do |arg|
      if RequestStatus.include? arg
        arg = arg.to_s + '='
        self.send arg, true
      end
    end
  end
  
  #convenience method to assign multiple type flags
  def type= args 
    args = [args] unless args.is_a? Array
    args.each do |arg|
      if RequestType.include? arg
        arg = arg.to_s + '='
        self.send arg, true
      end
    end
  end
  
  # TODO investigate Wip::VALID_TASKS - [:sleep, :ingeset] to have one place for it all

  many_to_one :agent
  many_to_one :package

  def cancel
    self.canceled = true
    self.save
  end

  # create a wip from this request
  def dispatch

    begin

      # make a wip
      dp_path = File.join archive.dispatch_path, package.id
      ws_path = File.join archive.workspace.path, package.id
      Wip.make dp_path, type
      FileUtils.mv dp_path, ws_path

      # save and log
      Request.transaction do
        self.released_to_workspace = true
        self.save or raise "cannot save request"
        package.log "#{type} released", :notes => "request_id: #{id}"
      end

    rescue

      # cleanup wip on fs
      FileUtils.rm_r dp_path if File.exist? dp_path
      FileUtils.rm_r ws_path if File.exist? ws_path

      # re-raise
      raise
    end

  end

end
