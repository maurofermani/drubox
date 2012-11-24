require 'git'
require './config/yml.rb'

class Proyecto
	
	#PROJECT_FOLDER = "drubox_files"
	#PROJECTS_PATH = File.expand_path("../../..",$0)+"/"+PROJECT_FOLDER


	DRUBOX_FOLDER = ENV["HOME"]+ "/" + YML::get("drubox_folder") # /home/usuario/Rubox

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
			
		@server_project_path = "git://127.0.01/"+@carpeta
	end	

	def pull()

		begin
			puts "ooo"
			@git.fetch('origin')
		rescue Git::GitExecuteError => error_git 
			puts "falla fetch\n"+error_git.to_s
			raise DownloadException, "Error al bajar los cambios desde el servidor" , caller
		else
			begin	
				merge_message = @git.gcommit('FETCH_HEAD').message
				puts merge_message
				@git.merge("origin/master","-m #{merge_message}: merge")
			rescue Git::GitExecuteError => error_git 
				if(error_git.to_s.include?("not something we can merge"))
					puts "veeerr: "+error_git.to_s #no hay 1er commit 
				else #hay conflicto :(				

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
				end
			end
		end
	end

	def push()
		@git.push('origin','master')
	end

	def abrirProyecto()
	
		if(File.directory?(@project_path))
			if(File.directory?(@project_path+"/.git"))
				@git = Git.open(@project_path)
				begin
					@git.add_remote('origin',@server_project_path)
					Logger.log(@carpeta,3,"Se agrego el remote origin = "+@server_project_path)	
				rescue Git::GitExecuteError => error_git #remote ya creado
					Logger.log(@carpeta,2,"El remote origin ya existe")	
				end
			else
				puts "existe sin git "+@carpeta		
			end		
		else
			puts "no existe "+@carpeta
			begin			
			@git = Git.clone(@server_project_path,@carpeta,{:path => @user_projects_path})	
			rescue Git::GitExecuteError => e
				raise CloneProjectException, "Error al clonar el proyecto", caller
				Logger.log(@carpeta,1,"No se pudo clonar el proyecto")
			end
		end

		@project_path
	end

	def addFile(file, newPath = nil)
		path = (newPath == nil)? @project_path : newPath["path"]		
		if(added = !File.exists?(path+"/"+File.basename(file)))		
			FileUtils.cp(file, path+"/"+File.basename(file))
		end
		return added
	end

	def addFolder(folder, newPath = nil)
		path = (newPath == nil)? @project_path : newPath["path"]
		if(added = !File.exists?(path+"/"+File.basename(folder)))
			FileUtils.cp_r(folder, path+"/"+File.basename(folder))
		end
		return added
	end

	def prepareAddFiles(files, path)
		@prepareFiles = Array.new()
		files.each{ |f|
			newPath = @project_path+"/"+File.basename(f)
			@prepareFiles.push({ "path" => f, "repetido" => File.exists?(newPath), "reemplazar" => false, "newPath" => newPath })
		}
		return @prepareFiles
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
		#@git.status.each{ |s|
		#	puts "path: "+s.path.to_s
		#	puts "type: "+s.type.to_s
		#	puts "stage: "+s.stage.to_s
		#	puts "untracked: "+s.untracked.to_s
		#	puts "------------------"
		#}
		begin		
			@git.status
		rescue Git::GitExecuteError => error_git 
			puts "error git status: "+error_git.to_s
			return nil
		end
	end


	def stageFiles()
		begin
			first_commit = @git.log().first()
		rescue	Git::GitExecuteError => error_git #no hay 1er commit	
			puts error_git.to_s
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
			@git.commit(commit_message) if hayCambios?
		rescue Git::GitExecuteError => error_git #working dir clean?
			if (error_git.to_s.include?("nothing to commit"))
				puts "working directory clean"
			else
				puts error_git.to_s
			end
		end	
		pull()
		push()
	end

	def download(commit_message)
	
		stageFiles()

		begin
			@git.commit(commit_message) if hayCambios?
		rescue Git::GitExecuteError => e #working dir clean?
			if (e.to_s.include?("nothing to commit"))
				Logger.log(@carpeta,3,"No existen cambios en el working directory (Proyecto.download)")
			else
				
			end
		end		
		pull()
	end

	def refresh_old()
		@git.diff("HEAD~1","HEAD").each{ |f|
			if(f.type=="new") #new agregado
				puts "agregar: "+f.path		
			elsif(f.type=="deleted")  #deleted borrado
 				puts "borrar: "+f.path	
			end
		}
	end

	def getFileCommits(path)
		@git.log().object(path)
	end

	def recuperarArchivo(path, newFileName, sha)	
		# copiar el archivo rollbackeado con otro nombre, y hacerle un checkout al original al head para tener las 2 versiones...		
		puts "path: "+path		
		puts "newFileName: "+newFileName
		
		@git.checkout_file(sha,path)
		FileUtils.cp(path,newFileName)
		@git.checkout_file("HEAD",path)
	end

	def hayCambios?()
		cambios = @git.status.added.length() + @git.status.changed.length() + @git.status.untracked.length() + @git.status.deleted.length()
		return cambios!=0 
	end


end
