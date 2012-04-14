require 'pg'

# HSW "finder" class.
# mostly pseudocode, but probably would work...

class Bill
  # This is a public, 'global' var
  attr_accessor :hostname

  # Put whatever you need here to initialize the DB conn.
  def initialize(hostname="localhost")
    # localhost is the default if there's no arg
    @hostname = hostname
  end

  # public method on the class
  def self.find(id=nil)
    response = Hash.new
    begin
      conn = PGconn.open(:dbname => 'test')
      res = conn.exec('SELECT 1 AS a, 2 AS b, NULL AS c')
      # build your result hash however makes you happy
      res.getvalue(0,0) # '1'
      res[0]['b'] # '2'
      response['big_spender'] = 'frank'
    rescue
      # bad things happened
      response = nil # convention
    end
    return response
  end

end
