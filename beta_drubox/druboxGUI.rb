require 'Qt4'
require './ruboxTree.rb'
require './loginDialog.rb'
require './timeMachineDialog.rb'
require './usuario.rb'

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

	def enableActions(enable)
		#@iniciarSesionAction
		#@cerrarSesionAction
		#@salirAction
		@addFileAction.setEnabled(enable)
		@addFolderAction.setEnabled(enable)
		@removeAction.setEnabled(enable)
		@uploadAction.setEnabled(enable)
		@downAction.setEnabled(enable)
		@timeMachineAction.setEnabled(enable)
		@statusAction.setEnabled(enable)
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
		enableActions(false)
	end

	def quitDrubox()
		logout()
		close()
	end

	def projectSelected(index)
		if (index>0) and (index!=@currentIndex)
			@currentIndex = index		
			projectPath = @usuario.setCurrentProject(index-1)
			@tree = RuboxTree.new(nil,projectPath)
			setCentralWidget(@tree)
			@proyecto = @usuario.getCurrentProject()
			enableActions(true)
		end
	end

	def addFile()
		newPath = @tree.getSelectedFolder()		
		@files = Qt::FileDialog::getOpenFileNames(self,"Seleccione los archivos a agregar","/home")
		#@proyecto.prepareAddFiles(@files) #listado de archivos repetidos...
		#preguntar si se reemplazan
		#reemplazar lo que se reemplaza
		#pasar cambios a gui tree
		@proyecto.addFile(@files, newPath)
		@tree.addFile(@files, newPath)
	end

	def addFolder()
		newPath = @tree.getSelectedFolder()
		@folder = Qt::FileDialog::getExistingDirectory(self,"Seleccione las carpetas a agregar","/home",Qt::FileDialog::ShowDirsOnly)
		if(@folder!=nil)		
			@proyecto.addFolder(@folder, newPath) 
			@tree.addFolder(@folder, newPath)
		end
	end

	def remove()
		rm_path = @tree.removeSelectedItem()
		@proyecto.remove(rm_path) if(rm_path!=nil)
	end

	def upload()
		cm = Qt::InputDialog::getText(self,tr("Ingrese commmit message"),tr("Commit Message"),Qt::LineEdit::Normal, "", @ok)
		@proyecto.upload(cm)
		@tree.refresh()
	end

	def download()
		cm = Qt::InputDialog::getText(self,tr("Ingrese commmit message"),tr("Commit Message"),Qt::LineEdit::Normal, "", @ok)
		@proyecto.download(cm)
		@tree.refresh()
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
				@tree.addFile([newFileName], nil)
			end
		end
		
	end

	def getStatus()
		@tree.updateStatus(@proyecto.status())
	end

end #class

app = Qt::Application.new(ARGV)
#Qt::Application::setStyle("motif")
window = DRuboxWindow.new()
window.show()
app.exec()


