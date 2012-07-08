require 'net/http'

url = "http://localhost:3000/users/1?var=lala"

resp = Net::HTTP.get_response(URI.parse(url))

resp_text = resp.body

puts resp_text.to_s