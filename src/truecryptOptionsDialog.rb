class TruecryptOptionsDialog < Qt::Dialog

	MIN_SIZE = 0
	MAX_SIZE = 0
	DEFAULT_SIZE = 10485760 # 10 MB

	slots 'calculateSize()'

	def initialize(parent = nil)
		#Qt::TextCodec::setCodecForCStrings(Qt::TextCodec::codecForName("utf-8"))	
		super(parent)
				
		@kbRadio = Qt::RadioButton.new(tr("&KB"))
		@mbRadio = Qt::RadioButton.new(tr("&MB"))
		@gbRadio = Qt::RadioButton.new(tr("&GB"))

		@radioGroup = Qt::ButtonGroup.new()
		
		@radioGroup.addButton(@kbRadio)		
		@radioGroup.addButton(@mbRadio)
		@radioGroup.addButton(@gbRadio)

		@mbRadio.setChecked(true)
		
		messageLabel = Qt::Label.new("Tama\u00f1o:")
		@sizeField = Qt::LineEdit.new()
		@aceptar = Qt::PushButton.new(tr("&Aceptar"))
		connect(@aceptar,SIGNAL('clicked()'),self,SLOT('calculateSize()'))

		fieldLayout = Qt::HBoxLayout.new()
		fieldLayout.addWidget(messageLabel)
		fieldLayout.addWidget(@sizeField)
		fieldLayout.addWidget(@aceptar)

		radioLayout = Qt::HBoxLayout.new()
		radioLayout.addWidget(@kbRadio)
		radioLayout.addWidget(@mbRadio)
		radioLayout.addWidget(@gbRadio)
				
		mainLayout = Qt::VBoxLayout.new()
		mainLayout.addLayout(fieldLayout)
		mainLayout.addLayout(radioLayout)
		
		setLayout(mainLayout)

		setWindowTitle(tr('Opciones del directorio de trabajo'))
		setFixedHeight(sizeHint().height())

		@size = DEFAULT_SIZE 
	end

	def calculateSize()
		tmp_size = @sizeField.text()
		if (tmp_size.to_i.to_s == tmp_size) 
			selectedRadio = @radioGroup.checkedButton()
			case selectedRadio
			when @kbRadio
				 mult = 1024
			when @mbRadio
				 mult = 1024 * 1024
			when @gbRadio
				 mult = 1024 * 1024 * 1024
			end
			tmp_size = tmp_size.to_i * mult
			@size = tmp_size #if (tmp_size>=MIN_SIZE) and (tmp_size<=MAX_SIZE)
		end
		accept()
	end

	def getSize()
		@size
	end

end
