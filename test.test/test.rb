class Parent
  def parent
    puts 'parent'
  end
end

class Child < Parent
  def child
    puts 'child'
  end
end

c = Child.new
c.parent
c.child