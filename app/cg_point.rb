# Turns CGPoint class into a vector class.
class CGPoint

  def +(other)
    CGPoint.new(self.x + other.x, self.y + other.y)
  end

  def -(other)
    CGPoint.new(self.x - other.x, self.y - other.y)
  end

  def *(scalar)
    CGPoint.new(self.x * scalar, self.y * scalar)
  end

  def /(scalar)
    CGPoint.new(self.x / scalar, self.y / scalar)
  end

  def magnitude
    Math.sqrt(self.x.abs2 + self.y.abs2)
  end

  def inner_product(other)
    self.x * other.x + self.y * other.y
  end

end