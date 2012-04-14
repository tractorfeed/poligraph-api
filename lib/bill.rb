require 'pg'
require 'govkit'

# HSW "finder" for bills in the unicam.
# This pulls data from the NADC and the OpenStates API

class Bill
  # This is a public, 'global' var
  attr_accessor :hostname, :dbname, :username
  conn = nil
  password = nil

  # Put whatever you need here to initialize the DB conn.
  def initialize(db_creds)
    # localhost is the default if there's no arg
    @hostname = db_creds[:hostname]
    @dbname = db_creds[:dbname]
    @username = db_creds[:username]
    @password = db_creds[:password]
    @conn = PGconn.connect(@hostname, 5432, @username, @password ,@dbname)
  end

  # HACK!!!
  def run_query(query)
    unless @conn
      @conn = PGconn.connect(@hostname, 5432, @username, @password ,@dbname)
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

    # clean up user input
    bill_name = filter_bill_name bill_name

    # api response (-ish)
    response = Hash.new
    begin
      # contributor details, support or oppose? etc.
      response['contributors_detail'] = contributors_detail(bill_name) || Array.new

      # Contributor data (a.k.a. Principles, who gave $$$ indirectly)
      response['contributors'] = Array.new
      response['contributors_detail'].each do |cd|
        response['contributors'].push cd['id']
      end

      # Committees (groups of folks for/against this bill)
      response['committees_detail'] = committees_detail(bill_name)
      response['committees'] = Array.new
      response['committees_detail'].each do |cd|
        response['committees'].push cd['id']
      end

      # Lobbyists (these guys lobbied on someone's behalf for/against the bill)
      response['lobbyists_detail'] = lobbyists_detail(bill_name)
      response['lobbyists'] = Array.new
      response['lobbyists_detail'].each do |ld|
        response['lobbyists'].push ld['id']
      end

      # Specific data about the bill (OpenStates API)
      response['metadata'] = find_meta(bill_name) || Hash.new
    rescue
      # bad things happened
      response = nil # convention
    end
    close_db_conn
    return response
  end

  def contributors_detail(bill_name)
    # lookup table
    position = {'S' => 'Support', 'O' => 'Oppose', 'T' => 'Other'}

    # array to store results
    results = Array.new

    # Try and find the bill:
    res = run_query("SELECT * FROM LFORMD WHERE 'bill' = #{bill_name}")

    # deal with this hot mess
    res.each do |row|
      result = Hash.new
      result['id'] = res['principal_id']
      result['document_details'] = {'type' => 'lformd', 'doc_id' => res['document_id']}
      result['position'] = (position.has_key? res['position'] ? position[res['position']] : 'Unknown')
      results.push result
    end

    # send it on back!
    return results
  end

  def committees_detail(bill_name)

    # array to store results
    results = Array.new

    # Try and find the bill:
    res = run_query("SELECT * FROM FORMA1 WHERE 'bill' = #{bill_name}")

    # deal with this hot mess
    res.each do |row|
      result = Hash.new
      result['id'] = res['committee_id_number']
      result['document_details'] = {'type' => 'forma1', 'doc_id' => res['id']}
      if(res['Oppose Ballot Question'].nil)
        result['position'] = 'Unknown'
      elsif (res['Oppose Ballot Question'] == '1')
        result['position'] = 'Oppose'
      else
        result['position'] = 'Support'
      end
      results.push result
    end

    # send it on back!
    return results
  end

  def lobbyists_detail(bill_name)
    # lookup table
    position = {'S' => 'Support', 'O' => 'Oppose', 'T' => 'Other'}

    # array to store results
    results = Array.new

    # Try and find the bill:
    res = run_query("SELECT * FROM LFORMD WHERE 'bill' = #{bill_name}")

    # deal with this hot mess
    res.each do |row|
      result = Hash.new
      result['id'] = res['lobbyist_id']
      result['document_details'] = {'type' => 'lformd', 'doc_id' => res['document_id']}
      result['position'] = (position.has_key? res['position'] ? position[res['position']] : 'Unknown')
      results.push result
    end

    # send it on back!
    return results
  end

end
