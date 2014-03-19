#class Toy < NSManagedObject
#
#  #@attributes = [
#  #    { name: 'image', type: NSBinaryDataAttributeType }
#  #]
#
#  @relationships = [
#      { name: 'parts', destination: 'Part', inverse: 'toy'}
#  ]
#
#end
#
#class Part < NSManagedObject
#
#  @attributes = [
#      { name: 'red', type: NSFloatAttributeType },
#      { name: 'green', type: NSFloatAttributeType },
#      { name: 'blue', type: NSFloatAttributeType },
#      { name: 'x', type: NSFloatAttributeType },
#      { name: 'y', type: NSFloatAttributeType }
#  ]
#
#  @relationships = [
#      { name: 'toy', destination: 'Toy', inverse: 'parts' }
#  ]
#
#end
#
#class Circle < Part
#
#end

