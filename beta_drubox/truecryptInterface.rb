class TruecryptInterface

	DRUBOX_FOLDER = ENV["HOME"]+"/.drubox" # /home/usuario/.drubox

	def self.initDirs()
		#setupTC
		Dir.mkdir(DRUBOX_FOLDER) if(!File.directory?(DRUBOX_FOLDER))
		Dir.mkdir(DRUBOX_FOLDER+"/.hd") if(!File.directory?(DRUBOX_FOLDER+"/.hd"))
	end

	def self.createVolume(login, pw, size = 10485760)
		#crear volumen TC (DRUBOX_FOLDER+"/.hd/"+@username+".ci")) si no existe
		cryptVol = DRUBOX_FOLDER+"/.hd/"+login+".ci"
		pwVol = pw
		sizeVol = size #esto pedirlo al usuario
		randomFileVol = "/home/p4c/Escritorio/rrr/random.txt" #esto cambiarlo, generar el archivo en el momento y ver si despues se puede borrar
		
		`echo 5 | truecrypt -t -c #{cryptVol} --volume-type=normal --encryption="AES" --hash="SHA-512" -p="#{pwVol}" -k "" --random-source=#{randomFileVol} --size="#{sizeVol}"` if(!File.exists?(cryptVol))
	end

	def self.mountVolume(login, pw)
		mountPoint = DRUBOX_FOLDER+"/"+login
		Dir.mkdir(mountPoint) if(!File.directory?(mountPoint)) #punto de montaje
		
		cryptVol = DRUBOX_FOLDER+"/.hd/"+login+".ci"		
		pwVol = pw		

		`truecrypt #{cryptVol} #{mountPoint}/ -p "#{pwVol}" -k "" --non-interactive`
	end

	def self.unmountVolume(login)
		cryptVol = DRUBOX_FOLDER+"/.hd/"+login+".ci"
		
		`truecrypt -d #{cryptVol}`
	end

end
