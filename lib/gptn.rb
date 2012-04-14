require 'nokogiri'
require 'open-uri'
require 'json'

def find_routes
  routes = Array.new
  doc = Nokogiri::HTML.parse(open('http://www.gptn.org/trails/info'))
  doc.css('ul.details > li').each do |li|
    begin
      props = {}
      props['description'] = li.css('.trailspecs > p')[1].text
      #props['surface_type'] = li.css('.trailspecs li')[0].text.split(":").last.strip
      #props['other_connections'] = li.css('.trailspecs li')[2].text.split(":").last.strip
      #props['points_of_interest'] = li.css('.trailspecs li')[2].text.split(":").last.strip
      props['route_key'] = li.css('div.viewmaps > a')[0]['href'].split('/').last
      routes.push(props)
    rescue
      # no op
    end
  end
  return routes
end

def fetch_route(route)
  route_key = route.delete("route_key")
  props = route
  response = JSON.parse(open("http://api.mapmyfitness.com/4/Route/get_route?consumer_key=#{consumer_key}&route_key=#{route_key}&format=json").read)["result"]
  if(response["status"] > 0) # request succeeded
    jsonObj = {}
    jsonObj["type"] = "Feature"
    jsonObj["geometry"] = {}
    jsonObj["geometry"]["type"] = "LineString"
    jsonObj["geometry"]["coordinates"] = Array.new
    response["output"]["points"].each do |point|
      jsonObj["geometry"]["coordinates"].push([point["lng"], point["lat"]])
    end

    # Add more properties to the input object
    props["trail_name"] = response["output"]["route_name"]
    props["city"] = response["output"]["city"]
    props["state"] = response["output"]["state"]
    props["country"] = response["output"]["country"]
    props["zip"] = response["output"]["zip"]
    props["length"] = response["output"]["length"]

    # merge
    jsonObj["properties"] = props

    # all done
    return jsonObj
  else
    return nil
  end
end

def build_collection(routes)
  jsonObj = {}
  jsonObj["type"] = "FeatureCollection"
  jsonObj["features"] = Array.new
  routes.each do |rt|
    jsonObj["features"].push fetch_route(rt)
  end
  return jsonObj
end

def gptn_run
  routes = find_routes
  coll = build_collection(routes)
  json = coll.to_json
  return json
end
