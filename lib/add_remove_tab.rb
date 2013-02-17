require 'gtk2'
require 'utils'
require 'textView'

class AddRemoveTab

  def new_tab(tab, treeview, view_but)
    editor = Textview.new
    swin = Gtk::ScrolledWindow.new
    if tab.n_pages != 0
      pagenum = tab_name(tab).to_s
    else
      pagenum = 1.to_s
    end
    swin.add(editor)
    tab.append_page(swin,
    Gtk::Label.new("Untitled Document " + pagenum))
    tab.signal_connect("switch-page") do |a, b, current_page|
    buf = tab.get_nth_page(current_page).child.buffer
    buf.signal_connect("changed"){o=Utils.new;
    o.text_changed(tab);
    o.view_sensitive(tab, treeview, view_but)}
    o = Utils.new
    text = buf.text
    o.view_sensitive(text, treeview, view_but)
    end
  end
 
  def remove_tab(tab)
    # kaldirilmak istenen sayfa kayitli mi
    if tab.get_nth_page(tab.page).child.saved
      tab.remove_page(tab.page)
      return
    end
    dialog = Gtk::MessageDialog.new(nil, Gtk::Dialog::MODAL,
    Gtk::MessageDialog::QUESTION,
    Gtk::MessageDialog::BUTTONS_YES_NO,
    _("Your changes will be lost. Do you want to continue?"))
    if dialog.run == Gtk::Dialog::RESPONSE_YES
      tab.remove_page(tab.page)
    end
    dialog.destroy
  end
  

  def tab_name(tab)
    i = 0
    arr = Array.new
    pagenum = tab.n_pages
    while i < pagenum
      # child page
      page = tab.get_nth_page(i)
      label = tab.get_tab_label(page).text
      arr.push(label)
       i += 1
    end
    i = 1
    while i <= pagenum + 1
      if arr.index("Untitled Document "+i.to_s) == nil and
      arr.index("* Untitled Document "+i.to_s) == nil
        return i
      end
      i += 1
    end
 end
 
    

end
