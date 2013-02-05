#encoding: UTF-8
require 'filemagic'
require 'zlib'
require 'zip/zip'
require 'gettext'
require 'rubygems'
require 'gtk2'
require 'tempfile'
require 'webkit'
require './lang'

class Utils
  include GetText 
  @@filename = ""
  @@saved = true
  
  def lang_choice(win,lang)
      if not @@saved
        dialog = Gtk::MessageDialog.new(win, Gtk::Dialog::MODAL,
        Gtk::MessageDialog::QUESTION,Gtk::MessageDialog::BUTTONS_YES_NO,
        RESTART)
        if dialog.run == Gtk::Dialog::RESPONSE_YES
          dialog.destroy
          f = File.open("lang.rb","w")
          f.write("LANGUAGE=\"#{lang}\"")
          f.close
          IO.popen("ruby editor.rb")
          Gtk.main_quit
        else
          dialog.destroy
        end
      else
          f = File.open("lang.rb","w")
          f.write("LANGUAGE=\"#{lang}\"")
          f.close
          IO.popen("ruby editor.rb")
          Gtk.main_quit 
      end
  end

  def save_as(win,editor,temp)
      save(win,editor,temp)   
  end

  def save(win,editor,temp)
      if temp == "save_as"
        temp = @@filename
        @@filename = ""
      end
      # daha once hic kaydedilmemis
      if @@filename == ""
          dialog = Gtk::FileChooserDialog.new(SAVE, win, Gtk::FileChooser::ACTION_SAVE, nil,
          [Gtk::Stock::CANCEL,Gtk::Dialog::RESPONSE_CANCEL],
          [Gtk::Stock::SAVE, Gtk::Dialog::RESPONSE_APPLY ])
          dialog.show_all()
          if dialog.run  == Gtk::Dialog::RESPONSE_APPLY
            file = dialog.filename
            @@filename = file
            content = editor.buffer.text
            File.open(file, "w") { |f| f <<  content }
            IO.popen("gzip #{@@filename}")
            msg = Gtk::MessageDialog.new(dialog,
            Gtk::Dialog::DESTROY_WITH_PARENT, Gtk::MessageDialog::INFO,
            Gtk::MessageDialog::BUTTONS_OK, SAVED)
            msg.show_all()
            if msg.run == Gtk::Dialog::RESPONSE_OK
              msg.destroy
              dialog.destroy
            end
          else
            if temp != ""
              @@filename = temp
            end
            dialog.destroy
          end
          @@saved = true
      elsif @@saved
          return
      else
        content = editor.buffer.text
        File.open(@@filename, 'w') do |f|
        gz = Zlib::GzipWriter.new(f)
        gz.write(content)
        gz.close
        end
        @@saved = true
      end
  end
 
  def open_new_empty_file(win,editor) 
      if not @@saved
          which_func = "open_new_empty_file"
          will_change_lost(win,editor,which_func)
     else
        editor.buffer.text = ""
        @@saved = true
        @@filename = ""
    end
  end

  # kaydedilmis bir dosyayi acma
  def open_file(win,editor) 
      if not @@saved
          which_func = "open_file"
          will_change_lost(win,editor,which_func)
      else
          open_new_file(win,editor)
          # kaydedilmis dosya acilinca buf degisir 
          # buf tekrar true oldu
          @@saved = true
      end
  end 
  
  # dosya acikken yeni dosya acma icin dialog
  def will_change_lost(win,editor,which_func)
      dialog = Gtk::MessageDialog.new(win, Gtk::Dialog::MODAL,
      Gtk::MessageDialog::QUESTION,Gtk::MessageDialog::BUTTONS_YES_NO,
      CHANGE_WILL_LOST)
     if dialog.run == Gtk::Dialog::RESPONSE_YES
          dialog.destroy
          @@filename = ""
          editor.buffer.text = ""
          @@saved = true
          if which_func == "open_file"
              open_new_file(win,editor)
              # kayitli dosya acilinca bu degisir
              # saved tekrar true olmasi gerekir
              @@saved = true
          end
     else
         dialog.destroy
     end   
  end 

  def buf_changed(buf,view_but)
     @@saved = false
     if buf.text == ""
         view_but.set_sensitive(false)
      else
        view_but.set_sensitive(true)
      end
  end
  
  def preview(win,editor,manview)
      if @@filename == "" or @@saved == false
        msg = Gtk::MessageDialog.new(nil, Gtk::Dialog::DESTROY_WITH_PARENT, 
        Gtk::MessageDialog::INFO, Gtk::MessageDialog::BUTTONS_OK, UNSAVED)
        msg.show_all()
        if msg.run == Gtk::Dialog::RESPONSE_OK 
            msg.destroy
        end
        return
      end
      # dosya kayitli ise
      content = editor.buffer.text
      file = Tempfile.new('foo')
      file.write(content)
      file.rewind
      file.read
      fm = FileMagic.new
      if fm.file(file.path).scan(/troff/i).length == 0
        msg = Gtk::MessageDialog.new(nil, Gtk::Dialog::DESTROY_WITH_PARENT,
        Gtk::MessageDialog::INFO, Gtk::MessageDialog::BUTTONS_OK, PREVIEW_MAN_FILE)
        msg.show_all()
        if msg.run == Gtk::Dialog::RESPONSE_OK
            file.close
            file.unlink
            msg.destroy
        end
        return
      end
      output = IO.popen("man2html #{file.path}")
      str = output.readlines
      i = 5
      content = str[1]+str[2]+str[3]+"<meta http-equiv=\"Content-Type\" content=\"text/html;charset=UTF-8\"></HEAD><BODY>"
      while i< str.length do
          content = content + str[i]
          i = i + 1
      end
      manview.load_string(content,"text/html", "UTF-8", "file://home")   
      file.close
      file.unlink 
  end

  def open_new_file(win,editor)
        dialog = Gtk::FileChooserDialog.new(OPEN, win, Gtk::FileChooser::ACTION_OPEN, nil, 
        [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
        [Gtk::Stock::OPEN, Gtk::Dialog::RESPONSE_ACCEPT])
        dialog.show
        begin
          if dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
            @@saved = true
            file = dialog.filename
            @@filename = file
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
       rescue
         msg = Gtk::MessageDialog.new(nil, Gtk::Dialog::DESTROY_WITH_PARENT,
         Gtk::MessageDialog::INFO, Gtk::MessageDialog::BUTTONS_OK, OPEN_MAN_FILE_ERROR)
         msg.show_all()
         if msg.run == Gtk::Dialog::RESPONSE_OK
           msg.destroy
           dialog.destroy
         end
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
          Gtk::MessageDialog::BUTTONS_OK, NO_LABEL)
         dialogue.run
         dialogue.destroy
      end
      first = last = nil
  end
  
  # html dosyasina donusturme  
  def create_html_file(editor,win)
      dialog = Gtk::FileChooserDialog.new(SAVE, win, Gtk::FileChooser::ACTION_SAVE, nil,
      [Gtk::Stock::CANCEL,Gtk::Dialog::RESPONSE_CANCEL],
      [ Gtk::Stock::SAVE, Gtk::Dialog::RESPONSE_APPLY ])
      dialog.show_all() 
      if dialog.run  == Gtk::Dialog::RESPONSE_APPLY
          file = dialog.filename
          # yandaki textin bir dosya icine atilmasi
          content = editor.buffer.text
          File.open(file, "w") { |f| f <<  content }
          # ayni textin htmlye donusturulmesi
          fm = FileMagic.new
          if fm.file(file).scan(/troff/i).length == 0
            File.delete(file)
            msg = Gtk::MessageDialog.new(dialog,
            Gtk::Dialog::DESTROY_WITH_PARENT, Gtk::MessageDialog::INFO,
            Gtk::MessageDialog::BUTTONS_OK, CREATE_MAN_FILE_ERROR)
            msg.show_all()
            if msg.run == Gtk::Dialog::RESPONSE_OK
                  msg.destroy
                  dialog.destroy
                  return
            end
          end
          output = IO.popen("man2html #{file}")
          str = output.readlines
          i = 5
          content = str[1]+str[2]+str[3]+"<meta http-equiv=\"Content-Type\" 
          content=\"text/html;charset=UTF-8\"></HEAD><BODY>"
          while i< str.length do
            content = content + str[i]
            i = i + 1
          end
          File.open(file, "w") { |f| f <<  content }
          msg = Gtk::MessageDialog.new(dialog,
          Gtk::Dialog::DESTROY_WITH_PARENT, Gtk::MessageDialog::INFO,
          Gtk::MessageDialog::BUTTONS_OK, SAVED)
          msg.show_all()
          if msg.run == Gtk::Dialog::RESPONSE_OK
              msg.destroy
              dialog.destroy
          end
      else
          dialog.destroy
      end
  end
  def app_about
    w = Gtk::Window.new
    layout = Gtk::Layout.new
    info = Gtk::Label.new(APP_INFO)
    b = Gtk::Button.new
    l = Gtk::Label.new(OK)
    w.set_title(APP_ABOUT)
    w.set_default_size(330,300)
    b.add(l)
    layout.put(info,10,30)
    layout.put(b,250,240) 
    w.add(layout)
    w.show_all
    b.signal_connect("clicked"){w.destroy}
  end
  def help
    w = Gtk::Window.new
    w.show_all
    swin = Gtk::ScrolledWindow.new
    webview = WebKit::WebView.new
    w.set_title(HELP)
    w.set_size_request(500,500)
    webview.load_string(HELP_CONTENT,"text/html", "UTF-8", "file://home")
    swin.add(webview)
    w.add(swin)
    w.show_all
  end
end
