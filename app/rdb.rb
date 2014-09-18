#vertix decimation using Ramer Douglas Peucker algorithm
class RDP

  #Simplify an array using the Ramer Douglas Peucker algorithm.
  #
  #The actual algorithm is implemented in Polyline. This is just a simplier way to call it form arrays
  #
  #The array should read as simplify([x1,x2,x3...],[y1,y2,y3...])
  def self.simplify(x,y,tol=nil)
    p = if tol
          Polyline.new(x.zip(y).map{|a,b| Point.new(a,b)}).simplify(tol).to_a
        else
          Polyline.new(x.zip(y).map{|a,b| Point.new(a,b)}).simplify.to_a
        end
  end

  #Merge an array of vectors that have different abcissa
  #
  #The array should read as [[[x1...],[y1...]], [[x2...],[y2...]],...]
  def self.merge(*args)
    Polyline::merge(
        *args.map{|x,y| Polyline.new(x.zip(y).map{|a,b| Point.new(a,b)}) }
    ).to_a
  end

  # Define new x vector for a given [[x],[y]] vector
  #
  # usage : RDP.interpolate( [[x1,x2..],[y1,y2...]], [newx1,newx2...])
  def self.interpolate(inline,abs)
    pl = Polyline.new(
        inline[0].zip(inline[1]).map{|x,y| Point.new(x,y)}
    )
    return pl.interpolate(abs).to_a
  end

end

#Simple point, with cartesian coordinates
class Point
  attr_accessor :x, :y
  def initialize(x=0,y=0)
    @x = x
    @y = y
  end

  #console log
  def show
    puts "#{@x}\t#{@y}"
  end
end


#Polyline, represented as an array of points
class Polyline < Array

  def initialize(ary=nil)
    if ary
      ary.each do |el|
        self << el
      end
    end
  end

  #vertix decimation using Ramer Douglas Peucker algorithm
  def simplify(epsilon=0.01,hard_limit=nil)

    # 1% default tolerance. the tolerance should not be recomputed recursively, hence the hard_limit
    tol = hard_limit || (self.map{|p| p.y}.max - self.map{|p| p.y}.min)*epsilon

    l = Line.new.define_from_points(self.first, self.last)
    dmax = 0.0
    pmax = nil
    imax = nil

    #Look for the farthest point if any
    (1..self.size-2).each do |i|
      d = l.distance_to_point(self[i])
      if d > dmax and d > epsilon
        pmax = self[i]
        imax = i
        dmax = d
      end
    end

    if pmax # at least a point has to be taken into account
      sub1 = Polyline.new(self[0..imax])
      sub2 = Polyline.new(self[imax..-1])
      return Polyline.new((sub1.simplify(epsilon,tol) + sub2.simplify(epsilon,tol)).uniq)
    else
      #no point is found
      return Polyline.new([self.first, self.last])
    end
  end

  #vertix decimation using Ramer Douglas Peucker algorithm
  def simplify!(eps=normalized_epsilon)
    self.replace self.simplify(eps)
  end

  #Print all the points to stdout
  def show
    self.each { |point| point.show }
  end

  #Export the points to a file
  def export(file)
    File.open(file,'w') do |f|
      self.each {|point| f.puts "#{point.x}\t#{point.y}"}
    end
  end

  #Interpolate the polyline to obtain a new polyline, using the given X vector.
  def interpolate(abcisses)
    res = Polyline.new
    i = 0 # will go through all abcisses
    (0..self.size-2).each do |j|
      while i < abcisses.size and abcisses[i] <= self[j+1].x
        l = Line.new.define_from_points(self[j],self[j+1])
        y = abcisses[i] == self[j].x ? self[j].y : (-l.c - l.a*abcisses[i]).to_f/l.b
        res << Point.new(abcisses[i], y)
        i +=1
      end
    end
    return res
  end

  #Merge two polylines together
  def self.merge(*args)
    abs = args.reduce([]){|x,y| x += y.map{|el| el.x}}.uniq.sort
    res = Polyline.new
    (0..abs.size-1).each do |i|
      res << Point.new( abs[i] , args.map{|line| line.interpolate(abs)}.inject(0){|y,line| y+= (line[i].y rescue 0)})
    end
    return res
  end

  #Convert a polyline (array of vectors) to a ruby array
  def to_a
    x = self.map{|p| p.x}
    y = self.map{|p| p.y}
    return [x,y]
  end

end

#Line in a plane, defined by the equation ax + by + c = 0
class Line
  # ax + by + c = 0
  attr_accessor :a, :b, :c

  def initialize(a=0,b=0,c=0)
    @a = a
    @b = b
    @c = c
  end

  #Construct the line from two points
  def define_from_points(p,q)
    @a = q.y - p.y
    @b = p.x - q.x
    @c = p.y*(q.x - p.x) - p.x*(q.y - p.y)
    return self
  end

  #Euclidian distance from a point to the line
  def distance_to_point(p)
    ( @a*p.x + @b*p.y + @c).abs/Math.sqrt(a**2 + b**2).to_f
  end

  #Log all
  def show
    puts "#{@a.round(2)}x + #{@b.round(2)}y +#{@c.round(2)} = 0"
  end
end

