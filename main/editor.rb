require 'gtk2'

class Editor

  def initialize
	@win = Gtk::Window.new
	@win.set_title("RManEdit")
	@win.signal_connect('delete_event'){false}
	@win.resize(500,500)
	@win.signal_connect('destroy'){Gtk.main_quit}
	@win.set_window_position(Gtk::Window::POS_CENTER)
	@vbox = Gtk::VBox.new(false,2)
	toolBar
	win_contain
	@win.show_all()
  end
 
  def win_contain
	@hbox = Gtk::HBox.new(false,2)
	label1 = Gtk::Label.new("Label",true)
	@editor = Gtk::TextView.new
	label3 = Gtk::Label.new("View",true)
	@hbox.pack_start(label1,true,true,0)
	swin = Gtk::ScrolledWindow.new
	swin.add(@editor)
	@hbox.pack_start(swin,true,true,0)
	@hbox.pack_start(label3,true,true,0)
	@vbox.pack_start(@hbox,true,true,0)
  end

  def toolBar
	# undo redo counter
	@count = 2
	toolbar = Gtk::Toolbar.new
        toolbar.set_toolbar_style(Gtk::Toolbar::Style::ICONS)
        newtb = Gtk::ToolButton.new(Gtk::Stock::NEW)
        opentb = Gtk::ToolButton.new(Gtk::Stock::OPEN)
        savetb = Gtk::ToolButton.new(Gtk::Stock::SAVE)
	undotb = Gtk::ToolButton.new(Gtk::Stock::UNDO)
        redotb = Gtk::ToolButton.new(Gtk::Stock::REDO)
        sep = Gtk::SeparatorToolItem.new
        quittb = Gtk::ToolButton.new(Gtk::Stock::QUIT)

        toolbar.insert(0, newtb)
        toolbar.insert(1, opentb)
	toolbar.insert(2, undotb)
	toolbar.insert(3, redotb)
        toolbar.insert(4, savetb)
        toolbar.insert(5, sep)
        toolbar.insert(6, quittb)
	opentb.signal_connect("clicked"){on_opentb}
	undotb.signal_connect("clicked"){}
	redotb.signal_connect("clicked"){}
	quittb.signal_connect("clicked"){Gtk.main_quit}
	@vbox.pack_start(toolbar,false,false,0)
	@win.add(@vbox)
  end
 
  def on_opentb
	dialog = Gtk::FileChooserDialog.new("Open File",
                                     @win,
                                     Gtk::FileChooser::ACTION_OPEN,
                                     nil,
                                     [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
                                     [Gtk::Stock::OPEN, Gtk::Dialog::RESPONSE_ACCEPT])
	dialog.show

  end

  def on_undo
        @count = @count - 1
        if @count <= 0
            @undo.set_sensitive(false)
            @redo.set_sensitive(true)
        end
    end

    def on_redo
        @count = @count + 1
        if @count >= 5
            @redo.set_sensitive(false)
            @undo.set_sensitive(true)
        end
    end

end

app = Editor.new
Gtk.main
