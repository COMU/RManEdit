#encoding: UTF-8
require 'gettext'
require 'rubygems'
require 'gtk2'

class Editor
  
  include GetText


  def initialize
	bindtextdomain("editor", :path => "locale")
	GetText.set_locale_all("en")
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
	label1 = Gtk::Label.new(_("Etiket"),true)
	@editor = Gtk::TextView.new
	label3 = Gtk::Label.new(_("Görüntü"),true)
	@hbox.pack_start(label1,true,true,0)
	swin = Gtk::ScrolledWindow.new
	swin.add(@editor)
	@hbox.pack_start(swin,true,true,0)
	@hbox.pack_start(label3,true,true,0)
	@vbox.pack_start(@hbox,true,true,0)
  end

  def toolBar
	toolbar = Gtk::Toolbar.new
        toolbar.set_toolbar_style(Gtk::Toolbar::Style::ICONS)
        newtb = Gtk::ToolButton.new(Gtk::Stock::NEW)
        opentb = Gtk::ToolButton.new(Gtk::Stock::OPEN)
        savetb = Gtk::ToolButton.new(Gtk::Stock::SAVE)
	cuttb = Gtk::ToolButton.new(Gtk::Stock::CUT)
	copytb = Gtk::ToolButton.new(Gtk::Stock::COPY)
	pastetb = Gtk::ToolButton.new(Gtk::Stock::PASTE)
        sep = Gtk::SeparatorToolItem.new
        quittb = Gtk::ToolButton.new(Gtk::Stock::QUIT)

        toolbar.insert(0, newtb)
        toolbar.insert(1, opentb)
        toolbar.insert(2, savetb)
	toolbar.insert(3, cuttb)
	toolbar.insert(4, copytb)
	toolbar.insert(5, pastetb)
        toolbar.insert(6, sep)
        toolbar.insert(7, quittb)
	opentb.signal_connect("clicked"){on_opentb}
	savetb.signal_connect("clicked"){on_savetb}
	cuttb.signal_connect("clicked"){on_cuttb}
	copytb.signal_connect("clicked"){on_copytb}
	pastetb.signal_connect("clicked"){on_pastetb}
	newtb.signal_connect("clicked"){on_newtb}
	quittb.signal_connect("clicked"){Gtk.main_quit}
	@vbox.pack_start(toolbar,false,false,0)
	@win.add(@vbox)
  end

  def on_savetb
      dialog = Gtk::FileChooserDialog.new(_("Kaydet"), @win, Gtk::FileChooser::ACTION_SAVE, nil,
      [ Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL ],
      [ Gtk::Stock::SAVE, Gtk::Dialog::RESPONSE_APPLY ])	
	dialog.show_all()
          
      if dialog.run  == Gtk::Dialog::RESPONSE_APPLY
          file = dialog.filename
	  if File.exist?(file)
	      msg = Gtk::Dialog.new(_("Bilgilendirme"), dialog,
              Gtk::Dialog::DESTROY_WITH_PARENT,[Gtk::Stock::OK, Gtk::Dialog::RESPONSE_ACCEPT],
              [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_REJECT])
              msg.vbox.add(Gtk::Label.new(_("Aynı isme sahip bir dosya zaten var. Üzerine yazılsın mı?")))
              msg.show_all()
              if msg.run == Gtk::Dialog::RESPONSE_ACCEPT
		  content = @editor.buffer.text
                  File.open(file, "w") { |f| f <<  content }
                  msg.destroy
		  dialog.destroy
              else
                  msg.destroy
              end
	  else
              content = @editor.buffer.text
              File.open(file, "w") { |f| f <<  content } 
              msg = Gtk::MessageDialog.new(dialog,
              Gtk::Dialog::DESTROY_WITH_PARENT, Gtk::MessageDialog::INFO, 
              Gtk::MessageDialog::BUTTONS_OK, _("Kaydedildi"))
              msg.show_all()
              if msg.run == Gtk::Dialog::RESPONSE_OK
                  msg.destroy
                  dialog.destroy
              end
	  end
      else
          dialog.destroy
      end
  end  

  def on_opentb
      dialog = Gtk::FileChooserDialog.new(_("Dosya Aç"), @win, Gtk::FileChooser::ACTION_OPEN, nil, 
      [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
      [Gtk::Stock::OPEN, Gtk::Dialog::RESPONSE_ACCEPT])
      dialog.show
      if dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
          file = dialog.filename
        content = ""
	IO.foreach(file){|block|  content = content + "\n"+ block}
	@editor.buffer.text = content
      end
      dialog.destroy
   end 
  def on_newtb
      dialog = Gtk::MessageDialog.new(
      nil,
      Gtk::Dialog::MODAL,
      Gtk::MessageDialog::QUESTION,
      Gtk::MessageDialog::BUTTONS_YES_NO,
      _("Tüm değişiklikler kaybedilecek. Devam etmek istiyor musunuz?")
  )
  if dialog.run == Gtk::Dialog::RESPONSE_YES
	@editor.buffer.text = ""
  end	
  dialog.destroy
  end
  
  def on_cuttb
      clipboard = Gtk::Clipboard.get(Gdk::Selection::CLIPBOARD)
      @editor.buffer.cut_clipboard(clipboard, true)
  end

  def on_copytb
      clipboard = Gtk::Clipboard.get(Gdk::Selection::CLIPBOARD)
      @editor.buffer.copy_clipboard(clipboard)
  end
  
  def on_pastetb
      clipboard = Gtk::Clipboard.get(Gdk::Selection::CLIPBOARD)
      @editor.buffer.paste_clipboard(clipboard, nil, true)
  end
end

app = Editor.new
Gtk.main
