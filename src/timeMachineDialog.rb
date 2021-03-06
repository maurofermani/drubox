class TimeMachineDialog < Qt::Dialog

	slots 'showCommitInfo(int)','recuperarClicked()'

	def initialize(file, commits, parent = nil)
		super(parent)
		
		@list = Qt::ListWidget.new(self)

		@arr_commits = Array.new()		
	
		commits.each{ |c|
			@arr_commits.push({ "sha" => c.sha(), "author" => c.author.name()+" <"+c.author.email+">", "message" => c.message(), "a_date" => c.author_date, "c_date" => c.committer_date })
			@list.addItem(c.message())
 		}
			
		@folder = File.dirname(file)
		@extname = File.extname(file)	
		@filename = File.basename(file,@extname)

		shaLabel = Qt::Label.new(tr("Sha:"))
		authorLabel = Qt::Label.new(tr("Autor:"))
		committerdateLabel = Qt::Label.new(tr("Fecha y hora:"))

		@csLabel = Qt::Label.new("")
		@caLabel = Qt::Label.new("")
		@ccdLabel = Qt::Label.new("")

		infoLayout = Qt::GridLayout.new()

		infoLayout.addWidget(Qt::Label.new(tr("Archivo:")),0,0)
		infoLayout.addWidget(Qt::Label.new(file),0,1)
		infoLayout.addWidget(shaLabel,1,0)
		infoLayout.addWidget(@csLabel,1,1)
		infoLayout.addWidget(authorLabel,2,0)
		infoLayout.addWidget(@caLabel,2,1)
		infoLayout.addWidget(committerdateLabel,3,0)
		infoLayout.addWidget(@ccdLabel,3,1)


		recFileLabel = Qt::Label.new(tr("Nuevo nombre:"))
		@recLineEdit = Qt::LineEdit.new()
		
		@recuperarButton = Qt::PushButton.new(tr("&Recuperar"))		
		cancelarButton = Qt::PushButton.new(tr("&Cancelar"))	

		filenameLayout = Qt::HBoxLayout.new()
		filenameLayout.addWidget(recFileLabel)
		filenameLayout.addWidget(@recLineEdit)

		buttonsLayout = Qt::HBoxLayout.new()
		buttonsLayout.addWidget(@recuperarButton)
		buttonsLayout.addWidget(cancelarButton)

		leftLayout = Qt::VBoxLayout.new()
		leftLayout.addLayout(infoLayout)
		leftLayout.addLayout(filenameLayout)
		leftLayout.addLayout(buttonsLayout)

		centerLayout = Qt::HBoxLayout.new()
		centerLayout.addWidget(@list)
		centerLayout.addLayout(leftLayout)

		connect(@list,SIGNAL('currentRowChanged(int)'),self,SLOT('showCommitInfo(int)'))
		connect(cancelarButton,SIGNAL('clicked()'),self, SLOT('close()'))
		connect(@recuperarButton,SIGNAL('clicked()'),self, SLOT('recuperarClicked()'))
		
		setLayout(centerLayout)

		setWindowTitle(tr('Versiones anteriores - '+@filename+@extname ))
		#setFixedHeight(sizeHint().height())
	end

	def showCommitInfo(row)
		if(row>=0)		
			@csLabel.setText(@arr_commits[row]["sha"])
			@caLabel.setText(@arr_commits[row]["author"])
			@ccdLabel.setText(@arr_commits[row]["c_date"].strftime("%d-%m-%Y %H:%M:%S"))
			@recLineEdit.setText(@filename+"_"+@arr_commits[row]["c_date"].strftime("%d-%m-%Y_%H:%M:%S")+@extname)

			@selectedSha =  @arr_commits[row]["sha"]
			@newFileName = @recLineEdit.text()
		end
	end

	def recuperarClicked()
		accept()
	end

	def getNewFileName()
		#return @newFileName
		return @recLineEdit.text()
	end

	def getFolder()
		return @folder
	end

	def getSelectedSha()
		return @selectedSha
	end

end
