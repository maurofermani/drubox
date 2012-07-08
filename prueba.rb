require 'net/http'
require 'json'

url = "http://localhost:3000/users/1.json"

resp = Net::HTTP.get_response(URI.parse(url))

resp_text = resp.body

rh = JSON.parse(resp_text)

puts rh.class
puts rh[0].class

#rh.each do |u|
#  puts "Usuario "+u["id"].to_s+": "+u["name"]+" ("+u["login"]+")"
#end
