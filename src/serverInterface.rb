require "uri"
require 'net/http'
require 'json'
require './config/yml.rb'

class ServerInterface

	@@http = Net::HTTP.new(YML::get("server_host"), YML::get("server_port").to_i)

	# Realiza la autentificación del usuario contra el servidor Rails para luego poder consultar sus 
	# proyectos. Usa la URL http://<server_host>:<server_port>/sessions pasando los parámetros del usuario 
	# y contraseña con el método post y obtiene la cookie correspondiente que es enviada como header en
	# el resto de los métodos.
	def self.iniciarSesion(login,password)
		begin		
			url = "/sessions"
			data = "login=#{login}&password=#{password}"	
			resp, data = @@http.post(url, data)
			if (resp.class==Net::HTTPFound)		
				cookie_session = resp.response['set-cookie'].split('; ')[0]
				return cookie_session
			else
				return nil
			end
		rescue Exception => e
			raise ServerException, "Error en la conexion al iniciar sesion ", caller
		end
	end

	# Finaliza la sesión del usuario en el servidor Rails. Usa la URL http://<server_host>:<server_port>/logout
	def self.cerrarSesion(cookie)
		begin		
			headers = {
				'Cookie' => cookie
			}
			resp, data = @@http.get("/logout",headers)
		rescue Exception => e
			raise ServerException, "Error en la conexion al cerrar sesion", caller
		end
	end
	
	# Obtiene desde el servidor el id de los proyectos a los que el usuario tiene acceso, junto con el tipo de 
	# acceso, utilizando para ello la URL http://<server_host>:<server_port>/projects.json
	def self.listaProyectos(cookie)
		begin			
			headers = {
				'Cookie' => cookie
			}

			resp, data = @@http.get("/projects.json",headers)
			if (resp.class==Net::HTTPOK)
				rh = JSON.parse(resp.body)
				return rh
			else
				return nil
			end
		rescue Exception => e
			raise ServerException, "Error en la conexion al obtener la lista de proyectos", caller
		end
	end

	# Obtiene información específica de un proyecto como el nombre y su descripción. Usa la URL 
	# http://<server_host>:<server_port>/projects/<project_id>.json
	def self.infoProyecto(cookie, id)
		begin		
			headers = {
				'Cookie' => cookie
			}

			resp, data = @@http.get("/projects/#{id}.json",headers)

			if (resp.class==Net::HTTPOK)
				rh = JSON.parse(resp.body)
				return rh
			else
				return nil
			end
		rescue Exception => e
			raise ServerException, "Error en la conexion al obtener la informacion del proyecto", caller
		end
	end
end
