require './server.rb'
require './proyecto.rb'
require './truecryptInterface.rb'

class Usuario

	attr_reader :id, :nombre, :descripcion, :login

	def initialize()
		@cookie = nil
		@projects = nil
		@id = nil		
		@nombre = nil
		@mail = nil
		@currentProject = nil
	end

	def iniciarSesion(login,password)
		@cookie =Server::iniciarSesion(login,password)
		@login = login
		@password = password #ver...
		TruecryptInterface::initDirs() if (@cookie !=nil)
		return @cookie != nil
	end

	def tieneWorkspace?()
		TruecryptInterface::existsVolume?(@login)
	end

	def crearWorkspace(size = 10485760)
		TruecryptInterface::createVolume(@login, @password, size) if (@cookie !=nil)
	end

	def montarWorkspace()
		TruecryptInterface::mountVolume(@login, @password) if (@cookie !=nil)
	end

	def cerrarSesion()
		Server::cerrarSesion(@cookie)
		TruecryptInterface::unmountVolume(@login)
	end

	def cargarProyectos()
		@projects = Array.new()		
		proys = Server::listaProyectos(@cookie)
		proys.each { |p_id|
			#@proyectos.push(p['path'])
			p_info = Server::infoProyecto(@cookie, p_id['project_id'])
			@projects.push( Proyecto.new(p_info['id'], p_info['name'], p_info['description'], @login, p_id['type_id']) )
		}
		getProjectName()
	end

	def getProjectName()
		projectName = Array.new()
		@projects.each{	|p|
			projectName.push(p.nombre()+' ('+p.descripcion()+')')
		}
		return projectName
	end

	def getCurrentProject()
		@currentProject
	end

	def setCurrentProject(index)
		@currentProjectId = index
		@currentProject = @projects[index]
		puts "Indice proyecto: "+index.to_s+" -> "+@currentProject.nombre()
		@currentProject.abrirProyecto()
	end

	

end
