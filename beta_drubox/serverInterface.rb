require "uri"
require 'net/http'
require 'json'
require './config/yml.rb'

class ServerInterface

	@@http = Net::HTTP.new(YML::get("server_host"), YML::get("server_port").to_i)

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
			raise ServerException, "Error al iniciar sesion", caller
		end
	end

	def self.cerrarSesion(cookie)
		begin		
			headers = {
				'Cookie' => cookie
			}
			resp, data = @@http.get("/logout",headers)
		rescue Exception => e
			raise ServerException, "Error al cerrar sesion", caller
		end
	end

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
			raise ServerException, "Error al obtener la lista de proyectos", caller
		end
	end

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
			raise ServerException, "Error al obtener la informacion del proyecto", caller
		end
	end

	#def self.infoUsuario(cookie, id)
	#	headers = {
	#		'Cookie' => cookie
	#	}
	#
	#	resp, data = @@http.get("/users/#{id}.json",headers)
	#
	#	if (resp.class==Net::HTTPOK)
	#		rh = JSON.parse(resp.body)
	#		return rh
	#	else
	#		return nil
	#	end	
	#end
		
end
