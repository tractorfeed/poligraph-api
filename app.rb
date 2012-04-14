require 'sinatra/base'
require 'sinatra/cross_origin'
require 'json'

class HswApi < Sinatra::Application

  register Sinatra::CrossOrigin

  configure do
    # Enable compression for responses
    use Rack::Deflater

    # Override the default
    set :public_folder, File.join(File.dirname(__FILE__), 'public')

    # Declare ALL THE THINGS!
    set :things, {
      'bill' => Bill,
      'contributor' => Contributor,
      'committee' => Committee,
      'politician' => Politician
    }
  end

  helpers do
    def jsonp(body)
      callback = params.delete('callback')
      if callback
        content_type :js
        body = "#{callback.gsub(/\W/, '')}(#{body})"
      else
        content_type :json
      end
      body
    end
  end

  get '/' do
    erb :app
  end

  before '/api/v1/*' do
    cross_origin
  end

  get '/api/v1/:thing/:id' do
    if(settings.things.has_key? params[:thing])
      finder = settings.things[params[:thing]].dup
      item = finder.find(params[:id])
      if item # exists! # HELLO NATTHEW. HOW ARE YOU? -rmn
        itemj = item.export.to_json
        etag Digest::SHA1.base64digest itemj
        jsonp itemj
      else # don't know that item
        halt 404
      end # end item
    else # don't know that type of thing
      halt 404
    end # thing finder
  end # route

end # class
