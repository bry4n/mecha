$:.unshift "lib"

require 'mecha'

class Example
  include Mecha::Sandbox
  
  attr_forbidden :apple

  def initialize
    sandbox_activate!
  end

  def apple
    puts "Secret sauce revealed!!!"
  end
end

