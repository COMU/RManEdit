#encoding: UTF-8
require 'filemagic'
require 'zlib'
require 'zip/zip'
require 'gettext'
require 'rubygems'
require 'gtk2'

class Utils
  include GetText 
  @@changed = false
  # kaydet
  def on_savetb(win,editor)
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

  def open_new_empty_file(win,editor)
      if editor.buffer.text != ""
          which_func = "open_new_empty_file"
          will_change_lost(win,editor,which_func)
      end
  end
  # dosya acma
  def open_file(win,editor)
      if editor.buffer.text == ""
         open_new_file(win,editor)
      else
         which_func = "open_file"
         will_change_lost(win,editor,which_func)
      end
      
  end 
  
  # dosya acikken yeni dosya acma icin dialog
  def will_change_lost(win,editor,which_func)
      dialog = Gtk::MessageDialog.new(
      nil,
      Gtk::Dialog::MODAL,
      Gtk::MessageDialog::QUESTION,
      Gtk::MessageDialog::BUTTONS_YES_NO,
      _("Tüm değişiklikler kaybedilecek. Devam etmek istiyor musunuz?"))
     if dialog.run == Gtk::Dialog::RESPONSE_YES
          dialog.destroy
          editor.buffer.text = ""
          if which_func == "open_file"
              open_new_file(win,editor)
          end
     else
         dialog.destroy
     end   
  end
  
  def open_new_file(win,editor)
  dialog = Gtk::FileChooserDialog.new(_("Dosya Aç"), win, Gtk::FileChooser::ACTION_OPEN, nil, 
        [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
        [Gtk::Stock::OPEN, Gtk::Dialog::RESPONSE_ACCEPT])
        dialog.show
        if dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
          file = dialog.filename
          fm = FileMagic.new
      	  # gzip dosyasi
          if fm.file(file).scan(/gziP/i).length != 0
      	      gz = Zlib::GzipReader.new(open(file)).read
              editor.buffer.text = gz
          # zip dosyasi
       	  elsif fm.file(file).scan(/zip/i).length != 0
       	      Zip::ZipFile.open(file) do |zip_file|
       	      zip_file.each do |f|
              editor.buffer.text = zip_file.read(f)
                 end
               end			
          # herhangi bir text
      	  else
              content = ""
              IO.foreach(file){|block|  content = content + "\n"+ block}
              editor.buffer.text = content
          end
              dialog.destroy
         
       else
          dialog.destroy
       end
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
  # secilen etikete gitme 
  def label_find(find,editor)
      start = editor.buffer.start_iter
      first, last = start.forward_search(find, Gtk::TextIter::SEARCH_TEXT_ONLY, nil)
      if (first)    
          mark = editor.buffer.create_mark(nil, first, false)
          editor.scroll_mark_onscreen(mark)
          editor.buffer.delete_mark(mark)
          editor.buffer.select_range(first, last)
      else
          dialogue = Gtk::MessageDialog.new(nil, Gtk::Dialog::MODAL, Gtk::MessageDialog::INFO, 
          Gtk::MessageDialog::BUTTONS_OK, _("Bu etiketi girmemişsiniz"))
         dialogue.run
         dialogue.destroy
      end
      first = last = nil
  end
  
  # html dosyasina donusturme  
  def create_html_file(editor,win)
      dialog = Gtk::FileChooserDialog.new(_("Kaydet"), win, Gtk::FileChooser::ACTION_SAVE, nil,
      [Gtk::Stock::CANCEL,Gtk::Dialog::RESPONSE_CANCEL],
      [ Gtk::Stock::SAVE, Gtk::Dialog::RESPONSE_APPLY ])
      dialog.show_all() 
      if dialog.run  == Gtk::Dialog::RESPONSE_APPLY
          file = dialog.filename
          # yandaki textin bir dosya icine atilmasi
          content = editor.buffer.text
          File.open(file, "w") { |f| f <<  content }
          # ayni textin htmlye donusturulmesi
          output = IO.popen("man2html #{file}")
          str = output.readlines
          i = 0
          content = ""
          while i< str.length do
              content = content + str[i]
              i = i + 1
          end
          
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

end
