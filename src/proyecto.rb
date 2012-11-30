require 'git'
require './config/yml.rb'

class Proyecto
	
	#PROJECT_FOLDER = "drubox_files"
	#PROJECTS_PATH = File.expand_path("../../..",$0)+"/"+PROJECT_FOLDER


	DRUBOX_FOLDER = ENV["HOME"]+ "/" + YML::get("drubox_folder") # /home/usuario/Rubox
	SERVER_HOST = YML::get("server_host")

	attr_reader :id, :nombre, :descripcion, :accessType

	def initialize(id, nombre, descripcion, username, accessType)
		
		@id = id
		@nombre = nombre
		@descripcion = descripcion
		@carpeta = @nombre#.gsub(/ /,'')+"_id"+@id.to_s
		@username = username
		@accessType = accessType #1 owner, 2 write, 3 read

		@user_projects_path = DRUBOX_FOLDER+"/"+@username # /home/usuario/.drubox/login
		
		@project_path = @user_projects_path+"/"+@carpeta # /home/usuario/.drubox/login/proyecto
			
		@server_project_path = "git://" + SERVER_HOST + "/"+ @carpeta
	end	

	# Utiliza los comandos git-fetch y git-merge para descargar los cambios desde el repositorio central. 
	# En caso de que existan conflictos al hacer el merge y el auto merge falle se conservan las diferentes 
	# versiones de los archivos en conflicto.
	def pull()

		begin
			@git.fetch('origin')
		rescue Git::GitExecuteError => e
			raise DownloadException, "Error al bajar los cambios desde el servidor" , caller
		else
			begin	
				merge_message = @git.gcommit('FETCH_HEAD').message
				@git.merge("origin/master","-m #{merge_message}: merge")
			rescue Git::GitExecuteError => e 
				if(e.to_s.include?("not something we can merge")) or (e.to_s.include?("Not a valid object name FETCH_HEAD"))
					Logger::log(@carpeta, Logger::INFO,"El repositorio esta vacio") 
				elsif(e.to_s.include?("Automatic merge failed")) #hay conflicto				
					
					@git.each_conflict{ |f| 

						ours_commit = @git.gcommit('ORIG_HEAD')
						ours_author = ours_commit.author.name

						theirs_commit = @git.gcommit('MERGE_HEAD')
						theirs_author = theirs_commit.author.name

						if (ours_author == theirs_author)
						add_ours = " ("+ours_author+" v1)"
						add_theirs = " ("+theirs_author+" v2)"
						else
						add_ours = " ("+ours_author+")"
						add_theirs = " ("+theirs_author+")"
						end

						nombre = f.chomp(File.extname(f))

						fno = nombre+add_ours+File.extname(f)

						@git.checkout_file("--ours",f)
						File.rename(@project_path+"/"+f,@project_path+"/"+fno)

						fnt = nombre+add_theirs+File.extname(f)

						@git.checkout_file("--theirs",f)
						File.rename(@project_path+"/"+f,@project_path+"/"+fnt)
				
						@git.add(fno)
						@git.add(fnt)
						@git.remove(f)
				
					}
					@git.commit("#{merge_message}: merge commit")
				else				
					raise DownloadException, "Error al bajar los cambios desde el servidor" , caller 
				end
			end
		end
	end

	# Sube los cambios al repositorio central con el comando git-push
	def push()
		begin
			@git.push('origin','master')
		rescue Git::GitExecuteError => e
			if (e.to_s.include?("refspec master does not match any"))
				Logger::log(@carpeta,Logger::INFO,"No hay cambios para subir al servidor")
			else
				raise UploadException, "Error al subir los cambios al servidor" , caller
			end
		end
	end

	# En caso de que el proyecto ya exista en el espacio de trabajo del usuario, se utiliza el método 
	# open de la gema Git para crear el objeto que representa el respositorio local, que es utilizado 
	# en el resto de los métodos de la clase Proyecto. En caso de que el proyecto no exista en el 
	# espacio de trabajo del usuario se lo clona desde el servidor centrar utilizando el comando git-clone
	def abrirProyecto()
	
		if(File.directory?(@project_path))
			if(File.directory?(@project_path+"/.git"))
				@git = Git.open(@project_path)
			else
				Logger::log(@carpeta,Logger::ERROR,"Carpeta creada sin el repositorio inicializado")	
			end		
		else
			begin			
			@git = Git.clone(@server_project_path,@carpeta,{:path => @user_projects_path})	
			rescue Git::GitExecuteError => e
				Logger::log(@carpeta,Logger::ERROR,"No se pudo clonar el proyecto")
				raise CloneProjectException, "Error al clonar el proyecto", caller
			end
		end

		@project_path
	end

	# Permite consultar si un archivo o carpeta existe dentro de la carpeta del proyecto. Se utiliza 
	# desde DRuboxGUI para manejar el caso de agregar archivos o carpetas repetidos.
	def fileExists?(file, newPath = nil)
		path = (newPath == nil)? @project_path : newPath["path"]
		File.exists?(path+"/"+File.basename(file))
	end

	# Copia un archivo específico dentro de la carpeta del proyecto. Si el archivo ya existe se reemplaza.
	def addFile(file, newPath = nil)
		path = (newPath == nil)? @project_path : newPath["path"]		
		FileUtils.cp(file, path+"/"+File.basename(file))
	end

	# Copia una carpeta específica dentro de la carpeta del proyecto. Si la carpeta ya existe se reemplaza.
	def addFolder(folder, newPath = nil)
		path = (newPath == nil)? @project_path : newPath["path"]
		FileUtils.cp_r(folder, path)
	end

	# Elimina de la carpeta del proyecto el archivo o carpeta especificado.
	def remove(rm_path)
		# ver si hacer el git remove aca o dejarlo antes del sync como esta ahora
		if(File.ftype(rm_path) == 'directory')
			FileUtils.remove_dir(rm_path)
		else
			FileUtils.remove_file(rm_path)
		end
	end
	
	# Utiliza el comando git-status para obtener para cada archivo del proyecto su estado en el repositorio 
	# local. Los estados de un archivo son añadido, modificado o eliminado. 
	def status()
		begin		
			@git.status
		rescue Git::GitExecuteError => e
			Logger::log(@carpeta,Logger::WARNING,"Error en status (no hay primer commit)")
			return nil
		end
	end

	# En caso de que el proyecto en el repositorio local no tenga ningún commit previo, este es el método 
	# que se utiliza para obtener el estado de los archivos.
	def noCommitStatus()
		untrackedFiles = Array.new()		
		findFiles(@project_path, untrackedFiles)
		return untrackedFiles
	end

	def findFiles(path, files)
		Dir["#{path}/*"].each{ |f|
			if(File.ftype(f)!='directory')
				files.push(f)
			else
				findFiles(f, files)
			end
		}
	end

	# Utiliza el comando git-add para incluir los archivos con estado nuevo o modificado en el siguiente commit. 
	# También utiliza el comando git-remove para excluir del siguiente commit los archivos con estado eliminado.
	def stageFiles()
		begin
			first_commit = @git.log().first()
		rescue	Git::GitExecuteError => error_git #no hay 1er commit	
			Dir["#{@project_path}/*"].each{ |f|
			 @git.add(f)
			}
		else 
			@git.status.each{ |f|
			if (f.type =='D')
				@git.remove(f.path)
			else
				@git.add(f.path)
			end
		}
		end
	end

	# Es el método que se llama desde la interfaz gráfica DRuboxGUI para subir los cambios al servidor. 
	# Se ejecutan los mismos pasos que en el caso del download y a continuación se invoca el método 
	# push de la clase Proyecto.
	def upload(commit_message)
		
		stageFiles()
		
		begin
			@git.config("user.name",@username)
			@git.commit(commit_message) if hayCambios?
		rescue Git::GitExecuteError => e #working dir clean?
			if (e.to_s.include?("nothing to commit"))
				Logger.log(@carpeta,Logger::INFO,"No existen cambios en el working directory (Proyecto.download)")
			else
				raise CommitException, "Error al guardar los cambios", caller		
			end
		end
		pull()
		push()
	end

	# Es el método que se llama desde la interfaz gráfica DRuboxGUI para descargar los cambios desde el 
	# servidor. Usa los métodos stageFiles y hayCambios? de la clase Proyecto. Si hay cambios en el 
	# repositorio local se ejecuta el comando git-commit y finalmente se invoca el método pull de la clase 
	# Proyecto.
	def download(commit_message)
	
		stageFiles()

		begin
			@git.config("user.name",@username)
			@git.commit(commit_message) if hayCambios?
		rescue Git::GitExecuteError => e #working dir clean?
			if (e.to_s.include?("nothing to commit"))
				Logger.log(@carpeta,Logger::INFO,"No existen cambios en el working directory (Proyecto.download)")
			else
				raise CommitException, "Error al guardar los cambios", caller		
			end
		end		
		pull()
	end

	# Para un archivo específico se obtienen todos los commits donde el archivo fue modificado. Es utilizado 
	# desde la interfaz gráfica DRuboxGUI para obtener versiones anteriores de los archivos.
	def getFileCommits(path)
		commits = nil
		begin		
			first_commit = @git.log().first()		
			commits = @git.log().object(path)
		rescue Git::GitExecuteError => e
			if(e.to_s.include?("bad default revision"))
				Logger.log(@carpeta,Logger::INFO,"Error en git log (no hay primer commit)")		
			else
				raise GetCommitsException, "Error al obtener la versiones anteriores del archivo", caller
			end
		end
		return commits
	end

	# Para un archivo y un commit específico, se obtiene una versión del archivo con el estado que tenía en ese 
	# commit. Para eso utiliza el comando git-checkout. Primero se hace el checkout del archivo a la versión del 
	# commit indicado. Se lo copia con otro nombre y se vuelve a hacer el checkout del archivo a la última versión.
	def recuperarArchivo(path, newFileName, sha)	
		
		@git.checkout_file(sha,path)
		FileUtils.cp(path,newFileName)
		@git.checkout_file("HEAD",path)
	end

	# Consulta si existen cambios en el repositorio local. Es utilizado en los métodos download y upload de 
	# la clase Proyecto para determinar si es necesario ejecutar el comando git-commit.
	def hayCambios?()
		begin
			first_commit = @git.log().first()
		rescue	Git::GitExecuteError => e #no hay 1er commit		
			cambios = Dir["#{@project_path}/*"].size
		else
			cambios = @git.status.added.length() + @git.status.changed.length() + @git.status.untracked.length() + @git.status.deleted.length()
		end
		return cambios!=0 
	end


end
