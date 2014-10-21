class SceneCreatorViewController < UIViewController
  include CreatorViewControllerModule
  # Mode on top of the screen, add config button
  MODES = [:scene, :toy, :config, :new]
  attr_reader :main_view

  attr_accessor :tab_bar



  def loadView # preferable to viewDidLoad because not using xib
    puts "scene creator view controller load view"
    self.view = UIView.alloc.initWithFrame(@bounds)
    self.view.accessibilityLabel = 'sceneView'
    self.view.alpha = 0.0
    location_of_play = [95, 0]
    size_of_play = [@bounds.size.width - 190, @bounds.size.height]
    @main_view = SceneCreatorView.alloc.initWithFrame([location_of_play, size_of_play])
    @main_view.setGravity(Constants::DEFAULT_GRAVITY_Y)
    @main_view.setWind(Constants::DEFAULT_GRAVITY_X)    
    setup_colour_buttons
    @current_colour_view.current_colour_image = Swatch.images['brown']
    @main_view.current_colour = UIColor.brownColor
    setup_tool_buttons
    setup_mode_buttons(MODES)
    @tool_buttons[:grab].selected = true # the default, was :line
    setup_label(Language::SCENE_MAKER)   
    @id = rand(2**60).to_s
  end

  def viewDidAppear(animated)
    p "viewDidAppear"
    @main_view.change_label_text_to(Language::SCENE_MAKER)
    @main_view.add_delegate(self)
    @main_view.mode = :scene
    view.addSubview(@main_view)
    view.addSubview(@mode_view)    
    super    
  end

  def moveToActionBar
    if tab_bar != nil
      tab_bar.selectedIndex = 2
    end
  end

  # Show the scene box.
  def scene   
    p "show scene box ...."
    scenebox_view_controller = SceneBoxViewController.alloc.initWithNibName(nil, bundle: nil)
    scenebox_view_controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical
    scenebox_view_controller.modalPresentationStyle = UIModalPresentationPageSheet
    scenebox_view_controller.delegate = self
    scenebox_view_controller.state = @state
    presentViewController(scenebox_view_controller, animated: true, completion: nil)
  end

  # Closes the toy box.
  def close_toybox
    p 'close_toybox'
    dismissModalViewControllerAnimated(true, completion: nil)   
  end

  # Set background
  def setBackground(image)
    @main_view.setBackground(image) # if nil then clear
    @state.scenes[@state.currentscene].background = image   
  end

  # Show the toy box
  def toy
    p 'show toy box'
    toybox_view_controller = ToyBoxViewController.alloc.initWithNibName(nil, bundle: nil)
    toybox_view_controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical
    toybox_view_controller.modalPresentationStyle = UIModalPresentationPageSheet
    toybox_view_controller.delegate = self
    toybox_view_controller.state = @state
    presentViewController(toybox_view_controller, animated: true, completion: nil)    
  end

  # Called when a toy image is clicked on in the toy box view.
  def drop_toy(toy_index)
    p 'drop toy'
    # get the toy
    @main_view.add_toy(ToyInScene.new(@state.toys[toy_index]))
    #add toy's actions to scene
    @state.toys[toy_index].actions.each do |action|
      @main_view.add_action(action)
    end
    close_toybox
    grab
  end

  #called when a scene imae is chosen in the scene box view
  def drop_scene(scene_index)   
    scene = @state.scenes[scene_index]    
    @main_view.clear
    @main_view.setBackground(scene.background)

    setGravity(scene.gravityY)
    setWind(scene.gravityX)
    setBoundaries(scene.boundaries)    

    scene.edges.each do |edge|
      # draw edge
      case edge
        when CirclePart
          @main_view.add_stroke(CircleStroke.new(((edge.position)), edge.radius, edge.colour, 1))
        when PointsPart
          @main_view.add_stroke(LineStroke.new(Array.new(edge.points), edge.colour, ToyTemplate::TOY_LINE_SIZE*ToyTemplate::IMAGE_SCALE))
        else
      end
    end

    scene.toys.each do |toy|
      @main_view.add_toy(toy)  
      toy.old_position = toy.position 
    end
    
    @state.load_scene_actions(scene)
    @main_view.add_action(scene.actions)
    #update id
    @id = scene.identifier
    @state.currentscene = scene_index
    close_toybox
    grab
  end

  # Called when the view disappears.
  def viewWillDisappear(animated)
    p 'view will disappear'
    super
    # collect the scene information to pass on to the play view controller
    save_scene    
  end

  def refresh
    p "scene refresh"
    @main_view.setNeedsDisplay
  end

  def setBoundaries(boundaries)
    @main_view.setBoundaries(boundaries)    
  end

  def setGravity(gravity)
    @main_view.setGravity(gravity)    
  end
  def setWind(wind)
    @main_view.setWind(wind)    
  end

  def save_scene
    scene = @main_view.gather_scene_info
    scene.identifier = @id
    unless scene.edges.empty? and scene.toys.empty?
      @state.add_scene(scene)
    end    
  end

  def new
    save_scene    
    clear
  end
  
  def clear   
    @id = rand(2**60).to_s
    @main_view.clear
  end

end