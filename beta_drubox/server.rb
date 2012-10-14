require "uri"
require 'net/http'
require 'json'

class Server

	SERVER_IP = "127.0.0.1"
	SERVER_PORT = 3000

	@@http = Net::HTTP.new(SERVER_IP, SERVER_PORT)

	def self.iniciarSesion(login,password)
		url = "/sessions"
		data = "login=#{login}&password=#{password}"	
		resp, data = @@http.post(url, data)
		if (resp.class==Net::HTTPFound)		
			cookie_session = resp.response['set-cookie'].split('; ')[0]
			return cookie_session
		else
			return nil
		end
	end

	def self.listaProyectos(cookie)
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
	end

	def self.infoProyecto(cookie, id)
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
	end

	def self.infoUsuario(cookie, id)
		headers = {
			'Cookie' => cookie
		}

		resp, data = @@http.get("/users/#{id}.json",headers)

		if (resp.class==Net::HTTPOK)
			rh = JSON.parse(resp.body)
			return rh
		else
			return nil
		end	
	end
		
end
