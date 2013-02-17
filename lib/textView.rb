require 'gtk2'

class Textview < Gtk::TextView

  attr_accessor :saved
  attr_accessor :file_path

  def initialize

    super
    # dosya kayit durumu
    @saved = true
    # acilan her sekmenin yolu dil secimi icin gerekli
    @file_path = ""

  end
end


