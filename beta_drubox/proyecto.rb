class Proyecto

	#PROJECTS_PATH = "/home/p4c/Escritorio/ejrubyqt/drubox/drubox_files"
	#PROJECTS_PATH = "./drubox_files"
	PROJECT_FOLDER = "drubox_files"
	PROJECTS_PATH = File.expand_path($0).chomp($0)+PROJECT_FOLDER

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
		#puts PROJECTS_PATH
	end

	def abrirProyecto()
		if(File.directory?(PROJECTS_PATH+"/"+@carpeta))
			if(File.directory?(PROJECTS_PATH+"/"+@carpeta+"/.git"))
				puts "existe con git "+@carpeta		
			else
				puts "existe sin git "+@carpeta		
			end		
		else
			#crear repo, iniciar git y hacer pull	
			puts "no existe "+@carpeta
			Dir.mkdir(PROJECTS_PATH+"/"+@carpeta)
			@git = Git.init(PROJECTS_PATH+"/"+@carpeta)
			
		end
		#if(@tree!=nil)
			@tree = RuboxTree.new(nil,PROJECTS_PATH+"/"+@carpeta)
		#else
		#	@tree.populate()
		#end
	end
	

end
