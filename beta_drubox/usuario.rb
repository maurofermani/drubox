require './server.rb'
require './proyecto.rb'

class Usuario

	attr_reader :id, :nombre, :descripcion

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
		#if (@cookie !=nil)
			
		#end
		return @cookie != nil
	end

	def cargarProyectos()
		@projects = Array.new()		
		proys = Server::listaProyectos(@cookie)
		proys.each { |p_id|
			#@proyectos.push(p['path'])
			p_info = Server::infoProyecto(@cookie, p_id['project_id'])
			@projects.push( Proyecto.new(p_info['id'], p_info['name'], p_info['description']) )
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
		@currentProject.abrirProyecto()
		puts "Indice proyecto: "+index.to_s+" -> "+@currentProject.nombre()
	end

	

end
