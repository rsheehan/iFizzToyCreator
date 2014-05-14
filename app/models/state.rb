class State

  attr_accessor :toys, :scenes, :games # don't do the scenes and games yet
  # just starting to do the scenes - one anyway

  def initialize
    @toys = []
    # scenes include the actions at the moment
    @scenes = []
    load
    #@toys = []
    # check to see if any state is saved?

    # load the state if it is

  end

  # Adds a toy and saves the updated state.
  def add_toy(toy)
    @toys << toy
    save
  end

  # Adds a scene and saves the updated state.
  def add_scene(scene)
    @scenes << scene
    save
  end

  def save
    paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true)
    documents_path = paths.objectAtIndex(0) # Get the docs directory
    file_path = documents_path.stringByAppendingPathComponent('state') # Add the file name
    puts "Writing image to #{file_path}"
    writeStream = NSOutputStream.outputStreamToFileAtPath(file_path, append: false)
    if writeStream
      writeStream.open
      error = Pointer.new(:object)
      bytes = NSJSONSerialization.writeJSONObject(json_compatible, toStream: writeStream, options: 0, error: error)
      puts "saved #{bytes} bytes"
      writeStream.close
    end
  end

  def load
    paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true)
    documents_path = paths.objectAtIndex(0) # Get the docs directory
    file_path = documents_path.stringByAppendingPathComponent('state') # Add the file name
    readStream = NSInputStream.inputStreamWithFileAtPath(file_path)
    puts "error opening readStream" unless readStream
    if readStream
      readStream.open
      error = Pointer.new(:object)
      json_state = NSJSONSerialization.JSONObjectWithStream(readStream, options: 0, error: error)
      #puts "error value (not necessarily an error) #{error[0].localizedDescription}"
      readStream.close
      convert_from_json_compatible(json_state) if json_state
    end
  end

  def json_compatible
    json_state = {}
    json_toys = @toys.map { |toy| toy.to_json_compatible }
    json_state[:toys] = json_toys
    # here we will eventually do the scenes as well
    json_scenes = @scenes.map { |scene| scene.to_json_compatible }
    json_state[:scenes] = json_scenes

    json_state
  end

  # Extracts the toys (and eventually scenes) from the json compatible data.
  def convert_from_json_compatible(json_object)
    #error = Pointer.new(:object)
    #json_object = NSJSONSerialization.JSONObjectWithData(data, options: 0, error: error)
    json_toys = json_object[:toys]
    toys = []
    json_toys.each do |json_toy|
      id = json_toy[:id]

      #puts "id: #{id}"

      parts = []
      json_toy[:parts].each do |json_part|
        col = json_part[:colour]
        colour = UIColor.colorWithRed(col[:red]/ToyTemplate::ACCURACY, green: col[:green]/ToyTemplate::ACCURACY,
                                      blue: col[:blue]/ToyTemplate::ACCURACY, alpha: 1.0)
        rad = json_part[:radius]
        if rad # must be a circle part
          radius = rad/ToyTemplate::ACCURACY
          pos = json_part[:position]
          position = CGPointMake(pos[:x], pos[:y])/ToyTemplate::ACCURACY
          part = CirclePart.new(position, radius, colour)
        else # must be a points part
          points = []
          json_part[:points].each do |pt|
            point = CGPointMake(pt[:x]/ToyTemplate::ACCURACY, pt[:y]/ToyTemplate::ACCURACY)
            points << point
          end
          part = PointsPart.new(points, colour)
        end
        parts << part
      end
      toys << ToyTemplate.new(parts, id)
    end
    # then we can do the scenes as well
    @toys = toys

    json_scenes = json_object[:scenes]
    scenes = []
    if json_scenes
      json_scenes.each do |json_scene|
        puts 'processing scene'
      end
    end
    @scenes = scenes

  end

end