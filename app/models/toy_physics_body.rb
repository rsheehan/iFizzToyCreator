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
    collect(toy_parts)
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

    epsilon = 0.2
    while next_pts.length > Constants::MAX_CONVEX_HULL_POINTS
      next_pts = reduce_points_2(next_pts, epsilon)
      epsilon = epsilon + 0.2
    end
    next_pts
  end

  # Added by Minh
  def reduce_points_2(path_of_points, epsilon)
    x = []
    y = []
    path_of_points.each do |p|
      x << p.x
      y << p.y
    end
    zx, zy = RDP.simplify(x, y, epsilon)

    new_path = []
    for i in 0 ... zx.size
      new_path << CGPointMake(zx[i], zy[i])
    end
    new_path
  end

  #Previously implemented reduce points
  DISTANCE_OFF_PATH = 4
  def reduce_points(path_of_points)
    a, mid  = path_of_points[0..1]
    # find the distance from b to segment a-c
    new_path = [a]

    i = 2
    while i < path_of_points.length do
      b = path_of_points[i]
      if minimum_distance(mid, a, b) > DISTANCE_OFF_PATH
        new_path << mid
        a = mid
        mid = b
        i += 1
      else
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
    points = convex_hull.map { |p| CGPointMake(p.x, -p.y) * scale }
    points.reverse
  end

  # Too many points in the original so I want to reduce this.
  def reduced_convex_hull

  end

end