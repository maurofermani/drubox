require './serverInterface.rb'
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

	# Invoca al método iniciarSesion de la clase ServerInterface.
	def iniciarSesion(login,password)
		@cookie =ServerInterface::iniciarSesion(login,password)
		@login = login
		@password = password #ver...
		TruecryptInterface::initDirs() if (@cookie !=nil)
		return @cookie != nil
	end

	def tieneWorkspace?()
		TruecryptInterface::existsVolume?(@login)
	end

	# Invoca al método createVolume de la clase TruecryptInterface
	def crearWorkspace(size = 10485760)
		TruecryptInterface::createVolume(@login, @password, size) if (@cookie !=nil)
	end

	# Invoca al método mountVolume de la clase TruecryptInterface
	def montarWorkspace()
		TruecryptInterface::mountVolume(@login, @password) if (@cookie !=nil)
	end

	# Invoca al método unmountVolume de la clase TruecryptInterface y al método 
	# cerrarSesion de la clase ServerInterface
	def cerrarSesion()
		TruecryptInterface::unmountVolume(@login)
		ServerInterface::cerrarSesion(@cookie)
	end

	# Invoca a los métodos listaProyectos e infoProyecto de la clase ServerInterface para 
	# obtener los proyectos a los que el usuario tiene acceso y para cada uno crea un objeto 
	# de clase Proyecto.
	def cargarProyectos()
		@projects = Array.new()		
		proys = ServerInterface::listaProyectos(@cookie)
		proys.each { |p_id|
			#@proyectos.push(p['path'])
			p_info = ServerInterface::infoProyecto(@cookie, p_id['project_id'])
			@projects.push( Proyecto.new(p_info['id'], p_info['name'], p_info['description'], @login, p_id['type_id']) )
		}
		getProjectName()
	end

	# Devuelve una lista con los nombres y descripción de los proyectos a los que el usuario 
	# tiene acceso.
	def getProjectName()
		projectName = Array.new()
		@projects.each{	|p|
			projectName.push(p.nombre()+' ('+p.descripcion()+')')
		}
		return projectName
	end

	# Devuelve el proyecto con el que se está trabajando.
	def getCurrentProject()
		@currentProject
	end

	# Utilizado para seleccionar el proyecto con el que se desea trabajar. Invoca al método 
	# abrirProyecto de la clase Proyecto.
	def setCurrentProject(index)
		@currentProjectId = index
		@currentProject = @projects[index]
		@currentProject.abrirProyecto()
	end

	

end
