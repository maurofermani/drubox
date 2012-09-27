require './server.rb'
require './proyecto.rb'

class Usuario

	def initialize()
		@cookie = nil
		@proyectos = nil
	end

	def iniciarSesion(login,password)
		@cookie =Server::iniciarSesion(login,password)
		return @cookie != nil
	end

	def cargarProyectos()
		@proyectos = Array.new()		
		proys = Server::listaProyectos(@cookie)
		proys.each { |p_id|
			#@proyectos.push(p['path'])
			p_info = Server::infoProyecto(@cookie, p_id['project_id'])
			@proyectos.push( Proyecto.new(p_info['id'], p_info['name'], p_info['description']) )
		}
		return @proyectos
	end

	def getProyectos()
		return @proyectos
	end

end
