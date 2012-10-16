require 'git'

class Proyecto

	#PROJECTS_PATH = "/home/p4c/Escritorio/ejrubyqt/drubox/drubox_files"
	#PROJECTS_PATH = "./drubox_files"
	
	PROJECT_FOLDER = "drubox_files"
	PROJECTS_PATH = File.expand_path("../../..",$0)+"/"+PROJECT_FOLDER
	SERVER_PROJECTS_PATH = "/var/cache/git"

	attr_reader :id, :nombre, :descripcion, :tree

	def initialize(id, nombre, descripcion)
		@id = id
		@nombre = nombre
		@descripcion = descripcion
		@carpeta = @nombre#.gsub(/ /,'')+"_id"+@id.to_s
		@tree = nil
		
		#puts "file: "+__FILE__
		#puts "0: "+$0
		#puts "exp: "+File.expand_path($0)
		#puts "final: "+File.expand_path($0).chomp("/"+$0)
	end

	def pull()

		begin
			@git.fetch('origin')
		rescue Git::GitExecuteError => error_git #no se hizo el 1er commit
			puts "no hay 1er commit\n"+error_git
		else #1er commit ok :)
			begin	
				@git.merge("origin/master","-m update desde el server")
			rescue Git::GitExecuteError => error_git #hay conflicto :(

			#si no hay 1er commit, el fetch no falla.... hay q ver aca si es conflicto o directorio limpio
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
					File.rename(PROJECTS_PATH+"/"+@carpeta+"/"+f,PROJECTS_PATH+"/"+@carpeta+"/"+fno)

					fnt = nombre+add_theirs+File.extname(f)

					puts fnt							

					@git.checkout_file("--theirs",f)
					File.rename(PROJECTS_PATH+"/"+@carpeta+"/"+f,PROJECTS_PATH+"/"+@carpeta+"/"+fnt)
				
					@git.add(fno)
					@git.add(fnt)
					@git.remove(f)
				
				}
				@git.commit("finally...")
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
		@git.push('origin','master')
	end

	def abrirProyecto()
		if(File.directory?(PROJECTS_PATH+"/"+@carpeta))
			if(File.directory?(PROJECTS_PATH+"/"+@carpeta+"/.git"))
				puts "existe con git "+@carpeta
				@git = Git.open(PROJECTS_PATH+"/"+@carpeta)
				
				begin
					@git.add_remote('origin',SERVER_PROJECTS_PATH+"/"+@carpeta)	
				rescue Git::GitExecuteError => error_git #remote ya creado
					puts "Error origen ya existe: "+error_git.to_s	
				end
				
				pull()
				push()				

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
			@git = Git.clone(SERVER_PROJECTS_PATH+"/"+@carpeta,@carpeta,{:path => PROJECTS_PATH})	

			
		end
		#if(@tree!=nil)
			@tree = RuboxTree.new(nil,PROJECTS_PATH+"/"+@carpeta)
		#else
		#	@tree.populate()
		#end
	end

	def addFile(files, path)
				
		files.each{ |f|
			FileUtils.cp(f,PROJECTS_PATH+"/"+@carpeta+"/"+File.basename(f))	
			f.replace(PROJECTS_PATH+"/"+@carpeta+"/"+File.basename(f))
		}
		puts "ejem: "+files.to_s
		@tree.addFile(files, path)	
	end

	def addFolder(folder, path)
		FileUtils.cp_r(folder,PROJECTS_PATH+"/"+@carpeta+"/"+File.basename(folder))
		@tree.addFolder(PROJECTS_PATH+"/"+@carpeta+"/"+File.basename(folder))
	end

	def remove()
		rm_path = @tree.removeSelectedItem()
		# ver si hacer el git remove aca o dejarlo antes del sync como esta ahora
		if (rm_path!=nil)
			if(File.ftype(rm_path) == 'directory')
				FileUtils.remove_dir(rm_path)
			else
				FileUtils.remove_file(rm_path)
			end
		end
	end
	
	def status()
		#puts @git.status.pretty
		#sync()
	end

	def upload()
		@git.status.each{ |f|
			if (f.type =='D')
				@git.remove(f.path)
			else
				@git.add(f.path)
			end
		}
		begin
			@git.commit("prepare for upload")
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

	def download()
		@git.status.each{ |f|
			if (f.type =='D')
				@git.remove(f.path)
			else
				@git.add(f.path)
			end
		}
		begin
			@git.commit("prepare for download") ##ver esto... //pincha si no hay  nada para hacer commit...
		rescue Git::GitExecuteError => error_git #working dir clean?
			if (error_git.to_s.include?("nothing to commit"))
				puts "working directory clean"
			else
				puts error_git.to_s
			end
		end		
		pull()
	end

	

end
