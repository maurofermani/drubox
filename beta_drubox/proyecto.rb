require 'git'

class Proyecto
	
	#PROJECT_FOLDER = "drubox_files"
	#PROJECTS_PATH = File.expand_path("../../..",$0)+"/"+PROJECT_FOLDER
	SERVER_PROJECTS_PATH = "/var/cache/git"

	DRUBOX_FOLDER = ENV["HOME"]+"/.drubox" # /home/usuario/.drubox
	

	attr_reader :id, :nombre, :descripcion, :tree

	def initialize(id, nombre, descripcion, username)
		@id = id
		@nombre = nombre
		@descripcion = descripcion
		@carpeta = @nombre#.gsub(/ /,'')+"_id"+@id.to_s
		@username = username

		@user_projects_path = DRUBOX_FOLDER+"/"+@username # /home/usuario/.drubox/login	
		
		@project_path = @user_projects_path+"/"+@carpeta # /home/usuario/.drubox/login/proyecto
			
		@server_project_path = SERVER_PROJECTS_PATH+"/"+@carpeta
	end	

	def pull(commit_message)

		begin
			@git.fetch('origin')
		rescue Git::GitExecuteError => error_git #no se hizo el 1er commit
			puts "no hay 1er commit\n"+error_git
		else #1er commit ok :)
			begin	
				@git.merge("origin/master","-m #{commit_message}: merge")
			rescue Git::GitExecuteError => error_git #hay conflicto :(
							
			#si no hay 1er commit, el fetch no falla.... hay q ver aca si es conflicto o directorio limpio
				if(error_git.to_s.include?("not something we can merge"))
					puts "veeerr: "+error_git.to_s
				else 				

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
					@git.commit("#{commit_message}: merge commit")
				end
			ensure					
				#@git.push('origin','master')
			end
		end
	

		#puts @git.status.pretty
		#@git.add_remote('alfin',"ssh://localhost/var/cache/git/alfin")
		#@git.add_remote('ra',"/var/cache/git/alfin")
	
	
		#antes de esto agregar que revise si existe el remote origin y sino crearlo
		#controlar porque si no hay commits en origin pincha...
		#@git.pull("origin","origin/master","Pull desde el server....")		
		puts "salio"	
	end

	def push()
		begin
		@git.push('origin','master')
		rescue Git::GitExecuteError => error_git 
			puts "error en push: "+error_git.to_s
		end
		puts "fue push!!"
	end

	def abrirProyecto()

		#montar volumen TC en punto de montaje
		#seguir con logica anterior...
		
		#if(!File.directory?(@user_projects_path))
		#	Dir.mkdir(@user_projects_path)
		#end

		if(File.directory?(@project_path))
			if(File.directory?(@project_path+"/.git"))
				puts "existe con git "+@carpeta
				@git = Git.open(@project_path)
				
				begin
					@git.add_remote('origin',@server_project_path)	
				rescue Git::GitExecuteError => error_git #remote ya creado
					puts "Error origen ya existe: "+error_git.to_s	
				end
				
				#pull()
				#push()				

			else
				puts "existe sin git "+@carpeta		
			end		
		else
			#crear repo, iniciar git y hacer pull	
			
			puts "no existe "+@carpeta
			
			#Dir.mkdir(PROJECTS_PATH+"/"+@carpeta)
			#@git = Git.init(PROJECTS_PATH+"/"+@carpeta)
			#puts "ssh://localhost/var/cache/git/Mi\\ proyecto"
			#@git.add_remote('server',SERVER_PROJECTS_PATH+"/"+@carpeta)
			#@git.pull("server","server/master","Pull de server a "+@carpeta)
			@git = Git.clone(@server_project_path,@carpeta,{:path => @user_projects_path})	

			
		end
		#if(@tree!=nil)
		#	@tree = RuboxTree.new(nil,@project_path)
		#else
		#	@tree.populate()
		#end
		return @project_path
	end

	def addFile(files, newPath = nil)
		path = (newPath == nil)? @project_path : newPath["path"]		
		files.each{ |f|
			FileUtils.cp(f, path+"/"+File.basename(f))	
		}
	end

	def addFolder(folder, newPath = nil)
		path = (newPath == nil)? @project_path : newPath["path"]
		FileUtils.cp_r(folder, path+"/"+File.basename(folder))
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
		#puts @git.status.pretty
		#sync()
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
			@git.commit(commit_message)
		rescue Git::GitExecuteError => error_git #working dir clean?
			if (error_git.to_s.include?("nothing to commit"))
				puts "working directory clean"
			else
				puts error_git.to_s
			end
		end	
		pull(commit_message)
		push()
	end

	def download(commit_message)
	
		stageFiles()

		begin
			@git.commit(commit_message) ##ver esto... //pincha si no hay  nada para hacer commit...
		rescue Git::GitExecuteError => error_git #working dir clean?
			if (error_git.to_s.include?("nothing to commit"))
				puts "working directory clean"
			else
				puts error_git.to_s
			end
		end		
		pull(commit_message)
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


end
