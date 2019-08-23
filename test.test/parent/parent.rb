class Parent
  include Aa
  res = Response.rescue do |res|
    puts 'aaa'
  end
  def parent
    puts 'parent'
  end
end