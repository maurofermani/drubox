class CommitMessageDialog < Qt::Dialog

	slots 'loginClicked()'

	def initialize(parent = nil)
		super(parent)

		userLabel = Qt::Label.new(tr("&Usuario:"))
		@userEdit = Qt::LineEdit.new()
		userLabel.setBuddy(@userEdit)

		passwordLabel = Qt::Label.new(tr("&Password:"))
		@passwordEdit = Qt::LineEdit.new()
		@passwordEdit.setEchoMode(Qt::LineEdit::Password)
		passwordLabel.setBuddy(@passwordEdit)

		@loginButton = Qt::PushButton.new(tr("&Login"))
	
		closeButton = Qt::PushButton.new(tr("&Close"))

		connect(@loginButton,SIGNAL('clicked()'),self, SLOT('loginClicked()'))	
		connect(closeButton,SIGNAL('clicked()'),self, SLOT('close()'))
	
		userLayout = Qt::HBoxLayout.new()
		userLayout.addWidget(userLabel)
		userLayout.addWidget(@userEdit)

		passwordLayout = Qt::HBoxLayout.new()
		passwordLayout.addWidget(passwordLabel)
		passwordLayout.addStretch()
		passwordLayout.addWidget(@passwordEdit)

		buttonsLayout = Qt::HBoxLayout.new()
		buttonsLayout.addWidget(@loginButton)
		buttonsLayout.addWidget(closeButton)

		mainLayout = Qt::VBoxLayout.new()
		mainLayout.addLayout(userLayout)
		mainLayout.addLayout(passwordLayout)
		mainLayout.addLayout(buttonsLayout)

		setLayout(mainLayout)

		setWindowTitle(tr('Login'))
		setFixedHeight(sizeHint().height())
	end

	def loginClicked()
		puts "login clicked"
		accept()
	end

	def getUsuario()
		@userEdit.text()
	end

	def getPassword()
		@passwordEdit.text()
	end
end
