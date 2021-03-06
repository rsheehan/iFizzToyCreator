class State

  attr_accessor :toys, :scenes, :games, :currentscene, :game_info # don't do the scenes and games yet
  # just starting to do the scenes - one anyway

  def initialize
    @game_info = nil
    @toys = []
    @scenes = []
    @currentscene = 0
    @thread = nil
    load
    initToys    
  end

  def clearState
    @game_info = GameInfo.new
    @toys = []
    @scenes = []
    @currentscene = 0
    @thread = nil    
    initToys
    save
  end

  def initToys
    thereIsSceneToy = false
    @toys.each do |toy|
      if toy.identifier == Constants::SCENE_TOY_IDENTIFIER
        #@toys.delete(toy)
        part = CirclePart.new(CGPointMake(0, 0) * ToyTemplate::IMAGE_SCALE, 1, UIColor.clearColor)
        toy.parts = [part]
        thereIsSceneToy = true
      end
    end
    if thereIsSceneToy != true
      part = CirclePart.new(CGPointMake(0, 0) * ToyTemplate::IMAGE_SCALE, 1, UIColor.clearColor)
      toy = ToyTemplate.new([part], Constants::SCENE_TOY_IDENTIFIER)
      toy.stuck = true
      @toys << toy
    end
  end

  def returnSceneToy
    @toys.each do |toy|
      if toy.identifier == 0
        return toy
      end
    end
  end

  # Adds a toy and saves the updated state.
  def add_toy(toy)
    replaced = nil
    @toys.each_with_index do |element, index|
      if (element.identifier == toy.identifier)
        replaced = index
      end
    end
    if replaced.nil?
      @toys << toy
    else
      toy.actions = @toys[replaced].actions
      @toys[replaced] = toy
    end
  end

  def load_scene_actions(pos= @scenes[@currentscene])
    if pos.is_a? SceneTemplate
      scene = pos
    else
      scene = @scenes[pos]
    end
    actions = get_actions_from_toys(scene.toys)
    scene.add_actions(actions)
    actions
  end

  def get_actions_from_toys(toys)
    actions = []
    checked = []
    toys.each do |toy|
      actions << return_toy_actions(toy, checked)
    end
    actions.flatten!
    actions
  end

  def return_toy_actions(in_toy, completed=[])
    if in_toy.is_a? ToyInScene
      toy = in_toy.template
    else
      toy = in_toy
    end
    if completed.include?(toy.identifier)
      return []
    else
      completed << toy.identifier
    end
    actions = toy.actions.clone
    toy.actions.each do |action|
      if action[:effect_type] == :create_new_toy
        create_toy = (@toys.select{ |altToy| altToy.identifier == action[:effect_param][:id]}).first

        create_actions = return_toy_actions(create_toy, completed)
        create_actions.each do |creaction|
          if !actions.include?(creaction)
               actions << creaction
          end
        end
      end
    end
    actions.flatten!
    actions
  end

  # Adds a scene and saves the updated state.
  def add_scene(scene)
    replaced = nil
    @scenes.each_with_index do |element, index|
      if (element.identifier == scene.identifier)
        replaced = index
      end
    end

    if replaced.nil?
      @scenes << scene
      @currentscene = @scenes.length - 1
    else      
      @scenes[replaced] = scene
      @currentscene = replaced
    end
  end

  def is_saving
    return (not @thread.nil?)
  end

  def save
    p "save"
    if @thread.nil?
      @thread = Thread.new {
      paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true)
      documents_path = paths.objectAtIndex(0) # Get the docs directory
      file_name = 'temp' + Time.now.to_s
      file_path = documents_path.stringByAppendingPathComponent(file_name) # Add the file name
      puts "Writing image to #{file_path}"
      writeStream = NSOutputStream.outputStreamToFileAtPath(file_path, append: false)
      if writeStream
        writeStream.open
        error = Pointer.new(:object)
        bytes = NSJSONSerialization.writeJSONObject(json_compatible, toStream: writeStream, options: 0, error: error)

        puts "(*) Saved successfully #{bytes} bytes"
        writeStream.close
      end
      state_file_path = documents_path.stringByAppendingPathComponent('state')
      File.rename(file_path, state_file_path)

      #duplicated but I could not find any where how to copy file in rubymotion

      if @game_info.name != "Untitled"
        file_name = 'temp' + Time.now.to_s
        file_path = documents_path.stringByAppendingPathComponent(file_name) # Add the file name
        puts "Writing image to #{file_path}"
        writeStream = NSOutputStream.outputStreamToFileAtPath(file_path, append: false)
        if writeStream
          writeStream.open
          error = Pointer.new(:object)
          bytes = NSJSONSerialization.writeJSONObject(json_compatible, toStream: writeStream, options: 0, error: error)
          puts "(*) Saved successfully #{bytes} bytes"
          writeStream.close
        end
        fileNameGame = @game_info.name.downcase.tr(" ", "_") + ".ifizz"
        fileNameGamePath = documents_path.stringByAppendingPathComponent(fileNameGame)
        File.rename(file_path, fileNameGamePath)
      end
      @thread = nil
      }
    end
  end

  def getStringState
    paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true)
    documents_path = paths.objectAtIndex(0) # Get the docs directory

    fileNameGame = @game_info.name.downcase.tr(" ", "_") + ".ifizz"
    file_path = documents_path.stringByAppendingPathComponent(fileNameGame)

    #file_path = documents_path.stringByAppendingPathComponent("state") # Add the file name
    #puts "load file path = #{file_path}"
    string = IO.binread(file_path)
    string
  end

  def load(fileName = "state")
    if not @thread.nil?
      puts "Saving before loading?"
    end
    @thread = "lock"
    paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true)
    documents_path = paths.objectAtIndex(0) # Get the docs directory
    file_path = documents_path.stringByAppendingPathComponent(fileName.to_s) # Add the file name

    readStream = NSInputStream.inputStreamWithFileAtPath(file_path)
    puts "error opening readStream" unless readStream
    if readStream
      readStream.open
      error = Pointer.new(:object)
      json_state = NSJSONSerialization.JSONObjectWithStream(readStream, options: 0, error: error)
      readStream.close
      convert_from_json_compatible(json_state) if json_state
      puts "(*) Load successfully json successfully"
    end
    files = Dir.entries(documents_path)
    files.each do |file_name|
      if not file_name.match('temp').nil?
        File.delete(documents_path.stringByAppendingPathComponent(file_name))
      end
    end
    @thread = nil
  end

  def loadFromData(data)
    error = Pointer.new(:object)
    json_state = NSJSONSerialization.JSONObjectWithData(data.dataUsingEncoding(NSUTF8StringEncoding), options: 0, error: error)
    clearState
    convert_from_json_compatible(json_state) if json_state
    save
  end

  def json_compatible
    json_state = {}
    json_state[:game_info] = @game_info.to_json_compatible
    json_toys = @toys.map { |toy| toy.to_json_compatible }
    json_state[:toys] = json_toys
    # here we will eventually do the scenes as well
    @scenes.delete_if{|scene| not (scene.is_a? SceneTemplate)}
    json_scenes = @scenes.map { |scene| if scene.is_a? SceneTemplate
                                          scene.to_json_compatible
                                        end }
    json_state[:scenes] = json_scenes

    json_state
  end

  # Extracts the toys (and eventually scenes) from the json compatible data.
  def convert_from_json_compatible(json_object)
    json_game_info = json_object[:game_info]
    @game_info = jsonToGameInfo(json_game_info)

    json_toys = json_object[:toys]
    toys = []
    json_toys.each do |json_toy|
      toys << jsonToToy(json_toy)
    end
    # then we can do the scenes as well
    @toys = toys

    json_scenes = json_object[:scenes]
    scenes = []
    if json_scenes
      json_scenes.each do |json_scene|
        scenes << jsonToScene(json_scene)
      end
    end
    @scenes = scenes
    @currentscene = 0 #scenes.length - 1
  end

  def jsonToPart(json_part)
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
    part
  end

  def jsonToGameInfo(json_game)
    if json_game != nil
      name = json_game[:name]
      description = json_game[:description]
      @game_info = GameInfo.new(name, description)
    else
      @game_info = GameInfo.new
    end
  end

  def jsonToToyInScene(json_toy)
    toy_id = json_toy[:toy_id]
    template = nil
    #get toy template for id
    @toys.each do |toy|
      if toy.identifier == toy_id
        template = toy
      end
    end

    if not template
      template = jsonToToy(json_toy[:template])
    end

    if template
      toy = ToyInScene.new(template, json_toy[:zoom], json_toy[:ghost])
      toy.position = CGPointMake(json_toy[:position][:x],json_toy[:position][:y] )
      toy.angle = json_toy[:angle]
      toy
    else
      puts 'Template was nil'
    end
  end

  # Convert from Json to collection of toys
  def jsonToToy(json_toy)
    id = json_toy[:id]
    parts = []
    json_toy[:parts].each do |json_part|
      parts << jsonToPart(json_part)
    end
    toy = ToyTemplate.new(parts, id)
    toy.stuck = (json_toy[:stuck] == nil) ? false : json_toy[:stuck]
    toy.can_rotate = (json_toy[:can_rotate] == nil) ? true : json_toy[:can_rotate]
    toy.gravity = (json_toy[:gravity] == nil) ? true : json_toy[:gravity]
    toy.front = (json_toy[:front] == nil) ? Constants::Front::Right : json_toy[:front]
    toy.always_travels_forward = (json_toy[:always_travels_forward] == nil) ? false : json_toy[:always_travels_forward]

    actions = []
    if json_toy[:actions] != nil
      json_toy[:actions].each do |json_action|
        hash = {}.addEntriesFromDictionary(json_action)
        hash = hash.each_with_object({}){|(k,v), h| if (k == "action_type" or k == "effect_type")
                                                          h[k.to_sym] = v.to_sym
                                                        else
                                                          h[k.to_sym] = v
                                                        end }
        if hash[:effect_type] == :apply_force
          arrayPt = hash[:effect_param]
          hash[:effect_param] = CGPointMake(arrayPt[0], arrayPt[1])
        end
        actions << hash
      end
    end
    toy.actions = actions
    toy
  end

  # Convert from Json to collection of scene
  def jsonToScene(json_scene)
    if json_scene.nil?
      return nil
    end
    id = json_scene[:id]

    windValue = 0.0
    if json_scene[:wind].to_s != ""
      windValue = json_scene[:wind].to_f
    end
    gravityValue = -4.0
    if json_scene[:gravity].to_s != ""
      gravityValue = json_scene[:gravity].to_f
    end

    gravity = CGVectorMake(windValue, gravityValue)
    boundaries = json_scene[:boundaries]
    background = Constants::BACKGROUND_COLOUR_LIST[json_scene[:background].to_i]
    backgroundURL = json_scene[:backgroundURL]

    edges = []
    unless json_scene[:edges].empty?
      json_scene[:edges].each do |json_edge|
        edges << jsonToPart(json_edge)
      end
    end

    toys = []
    unless json_scene[:toys].empty?
     json_scene[:toys].each do |json_toy|
        if json_toy != nil          
          toys << jsonToToyInScene(json_toy)
        end
      end
    end

    unless toys.empty? and edges.empty?
      actions = []
      scene = SceneTemplate.new(toys, edges, actions, id, CGRectMake(0,0,0,0), gravity, boundaries, background, backgroundURL)
      scene
    end
  end
end