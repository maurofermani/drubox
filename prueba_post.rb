require "uri"
require 'net/http'

url = "http://localhost:3000/users/" #llamada al create del usuario 

#parametros del formulario del new del usuario
params = {
 "user[name]"=>"Nuevo",
 "user[login]"=>"Nuevo",
 "user[pass]"=>"Nuevo1234"
}


resp = Net::HTTP.post_form(URI.parse(url), params)

resp_text = resp.body

puts resp_text;
