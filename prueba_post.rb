require "uri"
require 'net/http'

#si la ruta para el create es parametro por post mas /users/
#url = "http://localhost:3000/users/" #llamada al create del usuario 

#parametros del formulario del new del usuario
#params = {
# "user[name]"=>"Nuevo",
# "user[login]"=>"Nuevo",
# "user[pass]"=>"Nuevo1234"
#}

url = "http://localhost:3000/projects.json"

params = {
  "project[name]" => "todo",
  "project[description]" => "prueba...",
  "user_id" => "1",
  "path" => "/home/nose"
}


resp = Net::HTTP.post_form(URI.parse(url), params)

resp_text = resp.body

puts resp_text;
