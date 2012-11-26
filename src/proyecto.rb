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

						puts fno
						#en lugar de cambiarle el nombre a los 2 archivos, cambiarlo solo al que no es el nuestro
						@git.checkout_file("--ours",f)
						File.rename(@project_path+"/"+f,@project_path+"/"+fno)

						fnt = nombre+add_theirs+File.extname(f)

						puts fnt							

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

	def fileExists?(file, newPath = nil)
		path = (newPath == nil)? @project_path : newPath["path"]
		File.exists?(path+"/"+File.basename(file))
	end

	def addFile(file, newPath = nil)
		path = (newPath == nil)? @project_path : newPath["path"]		
		FileUtils.cp(file, path+"/"+File.basename(file))
	end

	def addFolder(folder, newPath = nil)
		path = (newPath == nil)? @project_path : newPath["path"]
		FileUtils.cp_r(folder, path)
	end

	def remove(rm_path)
		# ver si hacer el git remove aca o dejarlo antes del sync como esta ahora
		if(File.ftype(rm_path) == 'directory')
			FileUtils.remove_dir(rm_path)
		else
			FileUtils.remove_file(rm_path)
		end
	end
	
	def status()
		begin		
			@git.status
		rescue Git::GitExecuteError => e
			Logger::log(@carpeta,Logger::WARNING,"Error en status (no hay primer commit)")
			return nil
		end
	end

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

	def recuperarArchivo(path, newFileName, sha)	
		# copiar el archivo rollbackeado con otro nombre, y hacerle un checkout al original al head para tener las 2 versiones...	
		
		@git.checkout_file(sha,path)
		FileUtils.cp(path,newFileName)
		@git.checkout_file("HEAD",path)
	end

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
