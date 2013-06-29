Gem::Specification.new do |s|
  s.name = "RManEdit"
  s.version = "2.0.2"
  s.summary = "Neccessary gems for RManEdit"
  s.description = "UNIX Manual Page Editor with Ruby & GTK"
  s.authors = ["Ebru Akagündüz"]
  s.email = "ebru.akagunduz@gmail.com"
  s.homepage = "https://github.com/COMU/RManEdit"
  s.files = Dir["bin/rmanedit","lib/install", "lib/utils.rb", "lib/textView.rb", "lib/add_remove_tab.rb", "constants"]
  s.require_paths = ["lib"]
  s.add_dependency('rubyzip')
  s.add_dependency('ruby-filemagic')
  s.add_dependency('gtk2')
  s.add_dependency('gtk-webkit-ruby', '0.0.5')
end
