require 'pg'
require 'govkit'

# HSW "finder" for bills in the unicam.
# This pulls data from the NADC and the OpenStates API

class Bill
  # This is a public, 'global' var
  attr_accessor :hostname, :dbname
  conn = nil

  # Put whatever you need here to initialize the DB conn.
  def initialize(hostname="localhost", dbname="nadc")
    # localhost is the default if there's no arg
    @hostname = hostname
    @dbname = dbname
    @conn = PGconn.open(:dbname => @dbname)
  end

  # HACK!!!
  def run_query(query)
    unless @conn
      @conn = PGconn.open(:dbname => @dbname)
    end
    return @conn.exec(query)
  end

  # close db conn
  def close_db_conn
    if @conn # we're connected?
      @conn.close # not anymore!
    end
  end

  # alphanumeric and underscores
  def filter_string(string)
    return string.gsub(/\W/, '')
  end

  # filter bill name, kinda naive.
  def filter_bill_name(name)
    type = filter_string(name.split(" ").first)
    number = filter_string(name.split(" ").last)
    return type + " " + number
  end

  # public method on the class
  def self.find(bill_name)
    response = Hash.new
    begin
      # Contributor data (a.k.a. Principles, who gave $$$ indirectly)
      response['contributors'] = find_contributors(bill_name) || Array.new

      # contributor details, support or oppose? etc.
      response['contributors_detail'] = contributors_detail(bill_name) || Array.new

      # Committees (groups of folks for/against this bill)
      response['committees'] = find_committees(bill_name) || Array.new

      # Lobbyists (these guys lobbied on someone's behalf for/against the bill)
      response['lobbyists'] = find_lobbyists(bill_name) || Array.new

      # Specific data about the bill
      response['metadata'] = find_meta(bill_name) || Hash.new
    rescue
      # bad things happened
      response = nil # convention
    end
    close_db_conn
    return response
  end

  def find_contributors(bill_name)

    # sanitize me cap'n
    bill_name = filter_bill_name bill_name    

    # Try and find the bill:
    res = run_query("SELECT 'principal_id' FROM LFORMD WHERE 'bill' = #{bill_name}")

  end

end
