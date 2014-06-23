# To create the physics body from a toy I am going to generate the convex hulls of each part,
# except for circles which are separate.
# If the convex hull of one part is completely inside the convex hull of another part it is
# ignored. NOT YET.
# Any line segments "close" to each other should be regarded as connected -- paths. NOT YET.
# A single separate line segment is expanded to a "thin" rectangle -- lines.
# A single separate point is treated as a circle (but without the ability to rotate) -- dots.

# UNFORTUNATELY it appears that each physics body has to be associated with a node.
# This means that I will either have to create some invisible nodes or else just one
# physics body which encloses all relevant parts. But the body must be convex.

class ToyPhysicsBody

  def initialize(toy_parts) #, toy_node)
    #parts = toy_template.parts
    collect(toy_parts)
    #add_lines_to_paths
    #puts "circles: #{@circles.length}"
    #puts "paths: #{@paths.length}"
    #@paths.each do |path|
    #  puts "    path size: #{path.points.length}, hull size: #{convex_hull(path.points).length}"
    #end
    #puts "lines: #{@lines.length}"
    #puts "dots: #{@dots.length}"

    # create the physics body
    # this is temporary code - gets convex hull of all path/line parts
    @all_points = []
    @paths.each do |part|
      part.points.each do |point|
        @all_points << point
      end
    end
    @dots.each do |part|
      part.points.each do |point|
        @all_points << point
      end
    end
    #convex_hull(all_points)

    ## at the moment only does the paths
    ## get the body of the first path
    #if @paths.length > 0
    #  hull = convex_hull(@paths.shift.points)
    #  #first_body = SKPhysicsBody.bodyWithPolygonFromPath(hull)
    #end
    #@paths.each do |path|
    #  #body = SKPhysicsBody.bodyWithPolygonFromPath(convex_hull(path.points))
    #  hull = convex_hull(path.points)
    #  # glue this body to the first body
    #  # NB: the bodies must already be part of a node
    #
    #  #SKPhysicsJointFixed.jointWithBodyA(first_body, bodyB: body, anchor: anchor)
    #end
  end

  def points_in_paths
    @paths.length
  end

  # The first separation of the parts into categories.
  def collect(parts)
    @circles = []
    @paths = []
    #@lines = []
    @dots = []
    parts.each do |part|
      case part
        when CirclePart
          @circles << part
        when PointsPart
          case part.points.length
            when 1
              @circles << CirclePart.new(part.points[0], 2.5, part.colour)
            #when 2
            #  @lines << part
            else
              @paths << part
          end
      end
    end
  end

  #CLOSE = 10
  ## Adds lines which are close to other lines to a path,
  ## removing them from the lines array.
  ## Should I also add paths which are close to each other into one path
  ## and what about lines which are close to a path?
  #def add_lines_to_paths
  #  new_paths = []
  #  for i in 0..@lines.length-2
  #    p0, p1 = @lines[i]
  #    for j in i+1..@lines.length-1
  #      p2, p3 = @lines[j]
  #      if (p0 - p2).magnitude < CLOSE or (p0 - p3).magnitude < CLOSE or (p1 - p2).magnitude < CLOSE or (p1 - p3).magnitude < CLOSE
  #        # at least two points are close together so put them in the same path
  #        new_path = [p0, p1, p2, p3]
  #        new_paths << @lines[i] << @lines[j]
  #      end
  #    end
  #  end
  #end

  def minimum_distance(vpoint, p0, p1)
    v0 = p0
    v1 = p1
    segment_length = distance(v0, v1)
    length_squared = segment_length * segment_length
    #if length_squared < 10.0 # not long
    #  return distance(v0, vpoint)
    #end
    t = (vpoint - v0).inner_product(v1 - v0) / length_squared
    return distance(v0, vpoint) if t < 0
    return distance(v1, vpoint) if t > 1
    projection = v0 + ((v1 - v0) * t)
    distance(projection, vpoint)
  end

  def distance(v0, v1)
    (v1 - v0).magnitude
  end

  # To find the orientation of ordered triplet p, q, r.
  # The function returns the following values:
  # 0 - p, q and r are colinear
  # 1 - clockwise
  # 2 - counter clockwise
  def orientation(p, q, r)
    val = (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y)
    return 0 if val == 0
    val > 0 ? 1 : 2
  end

# Uses Jarvis's algorithm - http://www.geeksforgeeks.org/convex-hull-set-1-jarviss-algorithm-or-wrapping/
# Assumes path has at least 3 points.
  def convex_hull(path = @all_points)
    # Turn Two points into Four
    if path.length < 2
      return []
    end
    if path.length == 2

      dline = path[0] - path[1]
      len = Math.sqrt( dline.x ** 2 + dline.y ** 2)
      new_points = []
      if dline.x.abs > dline.y.abs
        new_points[0] = CGPointMake(path[0].x, path[0].y+2)
        new_points[1] = CGPointMake(path[0].x, path[0].y-2)
        new_points[2] = CGPointMake(path[1].x, path[1].y-2)
        new_points[3] = CGPointMake(path[1].x, path[1].y+2)
      else
        new_points[0] = CGPointMake(path[0].x+2, path[0].y)
        new_points[1] = CGPointMake(path[0].x-2, path[0].y)
        new_points[2] = CGPointMake(path[1].x-2, path[1].y)
        new_points[3] = CGPointMake(path[1].x+2, path[1].y)
      end

      # new_points[0] = path[0]
      # new_points[3] = path[1]
      #
      #
      # puts "Length: " + len.to_s
      # puts "DLine: X " + dline.x.to_s + ", Y " + dline.y.to_s
      # dline = dline / (len/2)
      #
      # new_points[1] = CGPointMake(path[0].x - dline.x, path[0].y + dline.y)
      # new_points[2] = CGPointMake(path[1].x - dline.x, path[1].y + dline.y)

      path = new_points
    end
    next_pts = []
    # get leftmost point
    left = 0
    for i in 1..path.length-1
      left = i if path[i].x < path[left].x
    end
    p = left
    loop do
      q = (p + 1) % path.length # move around the list
      for i in 0..path.length-1
        q = i if orientation(path[p], path[i], path[q]) == 2
      end
      next_pts << path[q]
      p = q
      break if p == left
    end
    while next_pts.length > 12
      #puts "1 number of points in convex hull: #{next_pts.length}"
      next_pts = reduce_points(next_pts)
    end
    #puts "2 number of points in convex hull: #{next_pts.length}"
    next_pts
  end

  DISTANCE_OFF_PATH = 4

  def reduce_points(path_of_points)
    a, mid  = path_of_points[0..1]
    # find the distance from b to segment a-c
    new_path = [a]

    i = 2
    while i < path_of_points.length do
      b = path_of_points[i]
      if minimum_distance(mid, a, b) > DISTANCE_OFF_PATH
        #puts "keep"
        new_path << mid
        a = mid
        mid = b
        i += 1
      else
        #puts "remove"
        # remove mid from the path of points
        new_path << b
        a = b
        i += 1
        mid = path_of_points[i]
        i += 1
      end
    end
    new_path
  end

  def convex_hull_for_physics(scale)
    #dwidth = 0# size.width / 2
    #dheight = 0 #size.height / 2
    # reduce to the standard size
    #points = convex_hull.map {|p| p * ToyTemplate::IMAGE_SCALE }
    # fix positions according to (0,0) of the image size.
    # everything has to be up and to the right (I think)
    points = convex_hull.map { |p| CGPointMake(p.x, -p.y) * scale }
    points.reverse
  end

  # Too many points in the original so I want to reduce this.
  def reduced_convex_hull

  end

end