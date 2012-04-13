require './test'

class Apple < Example
  
  attr_forbidden :apple

end

a = Apple.new
a.apple
