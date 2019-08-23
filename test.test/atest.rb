# require 'parent/parent'

class Child < Parent
  def child
    puts 'child'
  end
end

c = Child.new
c.parent
c.child