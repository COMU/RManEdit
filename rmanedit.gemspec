# -*- encoding: utf-8 -*-
Gem::Specification.new do |s|
  s.name        = "RManEdit"
  s.version     = "1.0.0"
  s.summary     = "Neccessary gems for RManEdit"
  s.description = "UNIX Manual Page Editor with Ruby & GTK"
  s.authors     = ["Ebru Akagündüz"]
  s.email       = "ebru.akagunduz@gmail.com"
  s.homepage    = "https://github.com/COMU/RManEdit"
  s.files = Dir["bin/rmanedit","lib/install","lib/utils.rb", "lib/textView.rb", "lib/add_remove_tab.rb", "images/*"]
  s.require_paths = ["lib"]
end
