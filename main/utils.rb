#encoding: UTF-8
require 'filemagic'
require 'zlib'
require 'zip/zip'
require 'gettext'
require 'rubygems'
require 'gtk2'

class Utils
  include GetText 
  def on_savetb(win,editor)
      btn = Gtk::Button.new("Buton")
      dialog = Gtk::FileChooserDialog.new(_("Kaydet"), win, Gtk::FileChooser::ACTION_SAVE, nil,
      [Gtk::Stock::CANCEL,Gtk::Dialog::RESPONSE_CANCEL],
      [ Gtk::Stock::SAVE, Gtk::Dialog::RESPONSE_APPLY ])
      dialog.show_all()
      if dialog.run  == Gtk::Dialog::RESPONSE_APPLY
          file = dialog.filename
=begin
          if File.exist?(file)
              msg = Gtk::Dialog.new(_("Bilgilendirme"), dialog,
              Gtk::Dialog::DESTROY_WITH_PARENT,[Gtk::Stock::OK, Gtk::Dialog::RESPONSE_ACCEPT],
              [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_REJECT])
              msg.vbox.add(Gtk::Label.new(_("Aynı isme sahip bir dosya zaten var. Üzerine yazılsın mı?")))
              msg.show_all()
              if msg.run == Gtk::Dialog::RESPONSE_ACCEPT
                  content = editor.buffer.text
                  File.open(file, "w") { |f| f <<  content }
                  msg.destroy
                  dialog.destroy
              else
                  msg.destroy
              end
=end
              content = editor.buffer.text
              File.open(file, "w") { |f| f <<  content }
              msg = Gtk::MessageDialog.new(dialog,
              Gtk::Dialog::DESTROY_WITH_PARENT, Gtk::MessageDialog::INFO,
              Gtk::MessageDialog::BUTTONS_OK, _("Kaydedildi"))
              msg.show_all()
              if msg.run == Gtk::Dialog::RESPONSE_OK
                  msg.destroy
                  dialog.destroy
              end
      else
          dialog.destroy
      end
  end
  
  def on_opentb(win,editor)
      dialog = Gtk::FileChooserDialog.new(_("Dosya Aç"), win, Gtk::FileChooser::ACTION_OPEN, nil, 
      [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
      [Gtk::Stock::OPEN, Gtk::Dialog::RESPONSE_ACCEPT])
      dialog.show
      if dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
          file = dialog.filename
          fm = FileMagic.new
	  # dosya turu kontrol
          if fm.file(file).scan(/gziP/i).length != 0
		gz = Zlib::GzipReader.new(open("ls.1.gz")).read
		editor.buffer.text = gz
	 else 
		puts "**"
	 end
      dialog.destroy
      end
  end 
 
  def on_newtb(win,editor)
      dialog = Gtk::MessageDialog.new(
      nil,
      Gtk::Dialog::MODAL,
      Gtk::MessageDialog::QUESTION,
      Gtk::MessageDialog::BUTTONS_YES_NO,
      _("Tüm değişiklikler kaybedilecek. Devam etmek istiyor musunuz?"))
     if dialog.run == Gtk::Dialog::RESPONSE_YES
          editor.buffer.text = ""
     end   
     dialog.destroy
  end
 
  def on_cuttb(editor)
      clipboard = Gtk::Clipboard.get(Gdk::Selection::CLIPBOARD)
      editor.buffer.cut_clipboard(clipboard, true)
  end

  def on_copytb(editor)
      clipboard = Gtk::Clipboard.get(Gdk::Selection::CLIPBOARD)
      editor.buffer.copy_clipboard(clipboard)
  end
  
  def on_pastetb(editor)
      clipboard = Gtk::Clipboard.get(Gdk::Selection::CLIPBOARD)
      editor.buffer.paste_clipboard(clipboard, nil, true)
  end

end
