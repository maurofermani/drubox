require 'Qt4'
require './ruboxTree.rb'
require './loginDialog.rb'
require './timeMachineDialog.rb'
require './truecryptOptionsDialog.rb'
require './usuario.rb'
require './exceptions/openProjectException.rb'
require './exceptions/uploadException.rb'
require './exceptions/downloadException.rb'

class DRuboxWindow < Qt::MainWindow

	slots 'login()', 'projectSelected(int)','addFile()','addFolder()','remove()','upload()','download()','timeMachine()','logout()','quitDrubox()','getStatus()'

	def initialize(parent = nil)
		super(parent)		
		createActions()
		createMenus()
		createStatusBar()
		createToolBars()
		
		setWindowIcon(Qt::Icon.new('./images/ic32.png'))
		setWindowTitle("Rubox Desktop Application")

		@usuario = nil
		@currentIndex = 0
		
		resize(800,400)
		move(300,300)
	end

	def createActions()
		@iniciarSesionAction = Qt::Action.new(tr("&Iniciar Sesion"),self)
		@iniciarSesionAction.setIcon(Qt::Icon.new('./images/ic32.png'))
		@iniciarSesionAction.setStatusTip(tr("Iniciar sesion"))
		connect(@iniciarSesionAction,SIGNAL('triggered()'),self,SLOT('login()'))

		@cerrarSesionAction = Qt::Action.new(tr("&Cerrar Sesion"),self)
		@cerrarSesionAction.setIcon(Qt::Icon.new('./images/ic32.png'))
		@cerrarSesionAction.setStatusTip(tr("Cerrar sesion"))
		connect(@cerrarSesionAction,SIGNAL('triggered()'),self,SLOT('logout()'))

		@salirAction = Qt::Action.new(tr("&Salir"),self)
		@salirAction.setIcon(Qt::Icon.new('./images/ic32.png'))
		@salirAction.setStatusTip(tr("Salir de la aplicacion"))
		connect(@salirAction,SIGNAL('triggered()'),self,SLOT('quitDrubox()'))

		@addFileAction = Qt::Action.new(tr("Agregar &Archivo"),self)
		@addFileAction.setIcon(Qt::Icon.new('./images/File.png'))
		@addFileAction.setStatusTip(tr("Agregar archivo"))
		connect(@addFileAction,SIGNAL('triggered()'),self,SLOT('addFile()'))

		@addFolderAction = Qt::Action.new(tr("Agregar &Carpeta"),self)
		@addFolderAction.setIcon(Qt::Icon.new('./images/Folder.png'))
		@addFolderAction.setStatusTip(tr("Agregar carpeta"))
		connect(@addFolderAction,SIGNAL('triggered()'),self,SLOT('addFolder()'))

		@removeAction = Qt::Action.new(tr("&Eliminar"),self)
		@removeAction.setIcon(Qt::Icon.new('./images/Remove.png'))
		@removeAction.setStatusTip(tr("Eliminar archivo o carpeta"))
		connect(@removeAction,SIGNAL('triggered()'),self,SLOT('remove()'))

		@uploadAction = Qt::Action.new(tr("&Subir cambios"),self)
		@uploadAction.setIcon(Qt::Icon.new('./images/up_b.png'))
		@uploadAction.setStatusTip(tr("Subir los cambios al servidor..."))
		connect(@uploadAction,SIGNAL('triggered()'),self,SLOT('upload()'))

		@downAction = Qt::Action.new(tr("&Bajar cambios"),self)
		@downAction.setIcon(Qt::Icon.new('./images/down_b.png'))
		@downAction.setStatusTip(tr("Bajar los cambios del servidor..."))
		connect(@downAction,SIGNAL('triggered()'),self,SLOT('download()'))

		@timeMachineAction = Qt::Action.new(tr("&Maquina del tiempo"),self)
		@timeMachineAction.setIcon(Qt::Icon.new('./images/TimeMachine.png'))
		@timeMachineAction.setStatusTip(tr("Obtener versiones pasadas de los archivos..."))
		connect(@timeMachineAction,SIGNAL('triggered()'),self,SLOT('timeMachine()'))

		@statusAction = Qt::Action.new(tr("&Status"),self)
		@statusAction.setIcon(Qt::Icon.new('./images/status.png'))
		@statusAction.setStatusTip(tr("Obtener status de los archivos..."))
		connect(@statusAction,SIGNAL('triggered()'),self,SLOT('getStatus()'))		

		enableActions(false)
	end

	def createMenus()
		@ruboxMenu = menuBar().addMenu(tr("&Rubox"))
		@ruboxMenu.addAction(@iniciarSesionAction)
		@ruboxMenu.addAction(@cerrarSesionAction)
		@ruboxMenu.addAction(@salirAction)

		@addMenu = menuBar().addMenu(tr("&Agregar"))
		@addMenu.addAction(@addFileAction)
		@addMenu.addAction(@addFolderAction)
		@addMenu.addAction(@uploadAction)
		@addMenu.addAction(@downAction)
		@addMenu.addAction(@timeMachineAction)
	end

	def createToolBars()
		@ruboxToolBar = addToolBar(tr("&Rubox"))
		@ruboxToolBar.addAction(@iniciarSesionAction)

		@projectCombo = Qt::ComboBox.new()
		@projectCombo.setSizeAdjustPolicy(0)	
		
		@ruboxToolBar.addSeparator()
		@ruboxToolBar.addWidget(Qt::Label.new(tr("Proyectos: ")))
		@ruboxToolBar.addWidget(@projectCombo)

		@ruboxToolBar.addSeparator()
		@ruboxToolBar.addAction(@addFileAction)
		@ruboxToolBar.addAction(@addFolderAction)
		@ruboxToolBar.addAction(@removeAction)
		@ruboxToolBar.addAction(@uploadAction)
		@ruboxToolBar.addAction(@downAction)
		@ruboxToolBar.addAction(@timeMachineAction)
		@ruboxToolBar.addAction(@statusAction)
	end

	def createStatusBar()
		statusBar()
	end

	def enableActions(enable, accessType = 3)
		#@iniciarSesionAction
		#@cerrarSesionAction
		#@salirAction
		@addFileAction.setEnabled(enable)
		@addFolderAction.setEnabled(enable)
		@removeAction.setEnabled(enable)
		
		@downAction.setEnabled(enable)
		@timeMachineAction.setEnabled(enable)
		@statusAction.setEnabled(enable)
		
		if enable and (accessType.to_i==1 or accessType.to_i==2) 
			@uploadAction.setEnabled(enable)
		else
			@uploadAction.setEnabled(false)
		end
	end

	def login()
		if(@usuario == nil)
			loginDialog = LoginDialog.new(self)
			if(loginDialog.exec()==Qt::Dialog::Accepted)
				u = loginDialog.getUsuario()
				p = loginDialog.getPassword()
				@usuario = Usuario.new()
				if (@usuario.iniciarSesion(u,p))
					puts "Iniciada"

					#metodo de consulta en la calse usuario para saber si existe el dir de trabajo
					#consultar, y si no existe, preguntar tamaño y usar metodo para crearlo

					if(!@usuario.tieneWorkspace?())
						#leer tamaño	
						truecryptOptions = TruecryptOptionsDialog.new(self)	
						truecryptOptions.exec()
						size = truecryptOptions.getSize()
						puts "size: "+size.to_s
						@usuario.crearWorkspace(size)
					end
					@usuario.montarWorkspace()

					proyectos = @usuario.cargarProyectos()
								
					@projectCombo.addItem("Seleccionar...")
				
					model = @projectCombo.model()
					firstIndex = model.index(0,@projectCombo.modelColumn(),@projectCombo.rootModelIndex())
					firstItem = model.itemFromIndex(firstIndex)
					firstItem.setSelectable(false)
	
					proyectos.each{ |p|
						@projectCombo.addItem(p)
					}
					connect(@projectCombo,SIGNAL('currentIndexChanged(int)'),self,SLOT('projectSelected(int)'))
				else
					puts "No iniciada"
				end
			end
		end
	end

	def logout()
		@usuario.cerrarSesion() if(@usuario != nil)
		@usuario = nil
		@proyecto = nil
		@tree.clear() if(@tree != nil)
		@tree = nil
		@projectCombo.clear() if(@projectCombo != nil)
		@currentIndex = 0
		enableActions(false)
	end

	def quitDrubox()
		logout()
		close()
	end

	def projectSelected(index)
		begin
			if (index>0) and (index!=@currentIndex)
				@currentIndex = index		
				projectPath = @usuario.setCurrentProject(index-1)
				@tree = RuboxTree.new(nil,projectPath)
				setCentralWidget(@tree)
				@proyecto = @usuario.getCurrentProject()
				enableActions(true, @proyecto.accessType())
			end
		rescue Exception => e
			#error al abrir el proyecto
			@tree.clear() if(@tree!=nil)
			@projectCombo.setCurrentIndex(0) if(@projectCombo!=nil) and (@projectCombo.count()>0)
			@currentIndex = 0			
			enableActions(false)
			Qt::MessageBox::critical(self,tr('DRubox'),tr("Error al abrir el proyecto"))
		end
	end

	def addFile()
		begin		
			newPath = @tree.getSelectedFolder()		
			file = Qt::FileDialog::getOpenFileName(self,"Seleccione los archivos a agregar","/home")
			#@proyecto.prepareAddFiles(@files) #listado de archivos repetidos...
			#preguntar si se reemplazan
			#reemplazar lo que se reemplaza
			#pasar cambios a gui tree
			added = @proyecto.addFile(file, newPath)
			if added
				@tree.addFile(file, newPath)
			else
				Qt::MessageBox::warning(self,tr('DRubox'),tr("El archivo no fue agregado porque ya existe"))
			end
		rescue Exception => e
			Qt::MessageBox::critical(self,tr('DRubox'),tr("Error al agregar el archivo"))
			@tree.refresh() if(@tree!=nil)
		end
	end

	def addFolder()
		begin	
			newPath = @tree.getSelectedFolder()
			@folder = Qt::FileDialog::getExistingDirectory(self,"Seleccione las carpetas a agregar","/home",Qt::FileDialog::ShowDirsOnly)
			if(@folder!=nil)		
				added = @proyecto.addFolder(@folder, newPath) 
				if added
					@tree.addFolder(@folder, newPath)
				else
					Qt::MessageBox::warning(self,tr('DRubox'),tr("La carpeta no fue agregada porque ya existe"))
				end
			end
		rescue Exception => e
			Qt::MessageBox::critical(self,tr('DRubox'),tr("Error al agregar la carpeta"))
			@tree.refresh() if(@tree!=nil)
		end
	end

	def remove()
		begin				
			rm_path = @tree.removeSelectedItem()
			@proyecto.remove(rm_path) if(rm_path!=nil)
		rescue Exception => e
			Qt::MessageBox::critical(self,tr('DRubox'),tr("Error al eliminar el archivo o carpeta"))
			@tree.refresh() if(@tree!=nil)
		end
	end

	def upload()
		begin
		msg = (@proyecto.hayCambios?)? Qt::InputDialog::getText(self,tr("Mensaje"),tr("Commit Message"),Qt::LineEdit::Normal, "", @ok) : ""
		@proyecto.upload(msg)
		@tree.refresh()
		rescue Exception => e
			Qt::MessageBox::critical(self,tr('DRubox'),tr("Error al subir los cambios al servidor"))	
		end
	end

	def download()
		begin
		msg = (@proyecto.hayCambios?)? Qt::InputDialog::getText(self,tr("Mensaje"),tr("Commit Message"),Qt::LineEdit::Normal, "", @ok) : ""	
		@proyecto.download(msg)
		@tree.refresh()
		rescue  Exception => e
			puts e.to_s
			Qt::MessageBox::critical(self,tr('DRubox'),tr("Error al bajar los cambios desde el servidor"))
		end
	end

	def timeMachine()
		path = @tree.getSelectedFile()
		puts path
		if(path!=nil)
			commits = @proyecto.getFileCommits(path)	
			timeMachineDialog = TimeMachineDialog.new(path, commits, self)
			if(timeMachineDialog.exec()==Qt::Dialog::Accepted)
				newFileName = timeMachineDialog.getNewFileName()				
				@proyecto.recuperarArchivo(path, newFileName , timeMachineDialog.getSelectedSha())
				#@tree.addFile([newFileName], nil)
				@tree.refresh()
			end
		end
		
	end

	def getStatus()
		status = @proyecto.status()
		@tree.updateStatus(status) if(status!=nil)
	end

end #class

begin
Qt::TextCodec::setCodecForCStrings(Qt::TextCodec::codecForName("utf-8"))
app = Qt::Application.new(ARGV)
#Qt::Application::setStyle("motif")
window = DRuboxWindow.new()
window.show()
app.exec()
end


