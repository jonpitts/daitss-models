# NOTE: be sure to update storage side models if this schema changes!

unless DB.table_exists? (:packages)
  DB.create_table :packages do
    String :id, :size=>50, :primary_key=>true
    String :uri, :size=>50, :unique => true, :null=>false
    index :uri, :unique=>true, :name=>:unique_packages_uri
    foreign_key :project_id, :projects, :type=>'varchar(50)', :null=>false
    foreign_key :project_account_id, :projects, :key=>:account_id, :type=>'varchar(50)', :null=>false
    index [:project_id, :project_account_id], :name=>:index_packages_project
  end
end

# authoritative package record
class Package < Sequel::Model(:packages)
  plugin :validation_helpers
  #set default values
  def before_create
    super
    self.uri ||= "info:fda/" + self.id 
    #EggHeadKey
    s = rand(DIGITS).to_s(36).upcase
    s = s + "0" * (14 - s.length) # pad length to 14 chars if necesary
    s.insert(8, "_")
    s = 'E' + s
    self.id ||= s
  end
  #save defaults to raise on save failure. false returns nil
  self.raise_on_save_failure = false 
  def validate
    super
    validates_presence [:uri]
    validates_unique :uri
  end
  
  one_to_many :events
  one_to_many :requests
  one_to_one :sip
  one_to_one :aip #has 0..1
  one_to_one :intentity #has 0..1
  one_to_one :report_delivery #has 0..1

  many_to_one :project

  one_to_many :batch_assignments
  many_to_many :batches #has n, :through => :batch_assignments


  LEGACY_EVENTS = [
    'legacy operations data',
    'daitss v.1 provenance',
    'migrated from rejects db'
  ]

  FIXITY_PASSED_EVENTS = [
    'fixity success',
    'integrity success'
  ]

  FIXITY_FAILED_EVENTS = [
    'fixity failure',
    'integrity failure'
  ]

  def self.search(id)
    self.first(Sequel.like(:id,"%#{id}%"))
  end
  
  def normal_events
    events.order(Sequel.asc(:id)) - (fixity_passed_events + legacy_events + fixity_failed_events)
  end

  def fixity_events
    events.where(:name => (FIXITY_PASSED_EVENTS + FIXITY_FAILED_EVENTS)).order(Sequel.asc(:timestamp))
  end

  def fixity_passed_events
    events.where(:name => FIXITY_PASSED_EVENTS).order(Sequel.asc(:timestamp))
  end

  def fixity_failed_events
    events.where(:name => FIXITY_FAILED_EVENTS).order(Sequel.asc(:timestamp))
  end

  def legacy_events
    events.where(:name => LEGACY_EVENTS).order(Sequel.asc(:id))
  end

  # add an operations event for abort
  def abort user, note
    event = Event.new :name => 'abort', :package => self, :agent => user, :notes => note
    event.save or raise "cannot save abort event"
  end

  # make an event for this package
  def log name, options={}
    e = Event.new :name => name, :package => self
    e.agent = options[:agent] || Program["SYSTEM"]
    e.notes = options[:notes]
    e.timestamp = options[:timestamp] if options[:timestamp]
    unless e.save
      raise "cannot save op event: #{name} (#{e.errors.size}):\n#{e.errors.map.join "\n"}"
    end
  end

  # return a wip if exists in workspace, otherwise nil
  def wip
    ws_wip = Daitss.archive.workspace[id]

    if ws_wip
      ws_wip
    else
      bins = Daitss.archive.stashspace
      bin = bins.find { |b| File.exist? File.join(b.path, id) }
      bin.find { |w| w.id == id } if bin
    end

  end

  def stashed_wip
    bins = Daitss.archive.stashspace
    bin = bins.find { |b| File.exist? File.join(b.path, id) }
    bin.find { |w| w.id == id } if bin
  end

  def rejected?
    events.where(:name => 'reject').first or events.where(:name => 'daitss v.1 reject').first
  end

  def migrated_from_pt?
    events.where(:name => "daitss v.1 provenance").first
  end

  def status
    if self.aip
      'archived'
    elsif self.events.where(:name => 'reject').first
      'rejected'
    elsif self.wip
      'ingesting'
    elsif self.stashed_wip
      'stashed'
    else
      'submitted'
    end
  end

  def elapsed_time
    raise "package not yet ingested" unless status == 'archived'
    return 0 if self.id =~ /^E20(05|06|07|08|09|10|11)/ #return 0 for D1 pacakges

    event_list = self.events.where(:name => "ingest started") + self.events.where(:name => "ingest snafu") + self.events.where(:name => "ingest stopped") + self.events.where(:name => "ingest finished").first

    event_list.sort {|a, b| a.timestamp <=> b.timestamp}

    elapsed = 0
    while event_list.length >= 2
      elapsed += Time.parse(event_list.pop.timestamp.to_s) - Time.parse(event_list.pop.timestamp.to_s)
    end

    return elapsed
  end

  def d1?
    if aip and aip.xml
      doc = Nokogiri::XML aip.xml
      doc.root.name == 'daitss1'
    end
  end

  def dips
    if ! File.exist? archive.disseminate_path+'/'+project_account_id 
      []
    else	
      Dir.chdir archive.disseminate_path+'/'+project_account_id  do
        Dir['*'].select { |dip| dip =~ /^#{id}-\d+.tar$/ }
      end
    end
  end

  def queue_reject_report
    r = ReportDelivery.new :type => :reject
    (self.project.account.report_email == nil or self.project.account.report_email.length == 0) ? r.mechanism = :ftp : r.mechanism = :email
    r.package = self

    r.save
  end

  # new for diddesm
  def queue_dissemination_report
    r = ReportDelivery.new :type => :dissemination
    (self.project.account.report_email == nil or self.project.account.report_email.length == 0) ? r.mechanism = :ftp : r.mechanism = :email
    r.package = self

    r.save
  end

  def self.ordered_by_timestamp direction = :asc
    if direction == :asc 
      events.order(:timestamp)
    else
      events.order(:timestamp).reverse
    end
    #order = DataMapper::Query::Direction.new(events.timestamp, direction)
    #query = all.query
    #query.instance_variable_set("@order", [order])
    #query.instance_variable_set("@fields", [ 'events.timpestamp'])
    #query.instance_variable_set("@links", [relationships['events'].inverse])
    #all(query)
  end
end

