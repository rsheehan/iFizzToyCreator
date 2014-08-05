class SceneCreatorViewController < UIViewController

  include CreatorViewControllerModule

  MODES = [:scene, :toy, :new]

  attr_reader :main_view

  def loadView # preferable to viewDidLoad because not using xib
    # Can call super this time as super is not UIViewController

    # about to convert the self.view to the SceneCreatorView
    self.view = UIView.alloc.initWithFrame(@bounds)
    location_of_play = [95, 0]
    size_of_play = [@bounds.size.width - 190, @bounds.size.height]
    @main_view = SceneCreatorView.alloc.initWithFrame([location_of_play, size_of_play])

    #@main_view.add_delegate(self) Now done in viewDidAppear
    #view.addSubview(@main_view)
    setup_colour_buttons
    @current_colour_view.current_colour_image = Swatch.images['brown']
    @main_view.current_colour = UIColor.brownColor
    setup_tool_buttons
    setup_mode_buttons(MODES)
    @tool_buttons[:grab].selected = true # the default, was :line
    setup_label(Language::SCENE_MAKER)
    #assign an id to the toy being made
    @id = rand(2**60).to_s
  end

  def viewDidAppear(animated)
    @main_view.change_label_text_to(Language::SCENE_MAKER)
    @main_view.add_delegate(self)
    @main_view.mode = :scene

    view.addSubview(@main_view)

    view.addSubview(@mode_view)
    super
  end

  #def viewDidDisappear(animated)
  #  puts "viewDidDisappear"
  #  #@main_view.current_tool = :grab
  #  #select_button(:grab)
  #  #@tool_buttons[:grab].selected = true # the default, was :line
  #end

  # Show the scene box.
  def scene
    save_scene
    puts "Show the scene box"
    scenebox_view_controller = SceneBoxViewController.alloc.initWithNibName(nil, bundle: nil)
    scenebox_view_controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical
    scenebox_view_controller.modalPresentationStyle = UIModalPresentationPageSheet
    scenebox_view_controller.delegate = self
    scenebox_view_controller.state = @state
    presentViewController(scenebox_view_controller, animated: true, completion: nil)
  end

  # Closes the toy box.
  def close_toybox
    dismissModalViewControllerAnimated(true, completion: nil)
  end

  # Show the toy box
  def toy
    toybox_view_controller = ToyBoxViewController.alloc.initWithNibName(nil, bundle: nil)
    toybox_view_controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical
    toybox_view_controller.modalPresentationStyle = UIModalPresentationPageSheet
    toybox_view_controller.delegate = self
    toybox_view_controller.state = @state
    presentViewController(toybox_view_controller, animated: true, completion: nil)
    #toybox_view_controller.setup_toys(@state.toys)
  end

  # Called when a toy image is clicked on in the toy box view.
  def drop_toy(toy_index)
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
    #do something here to load scene
    scene = @state.scenes[scene_index]
    @main_view.clear
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
      #add toy's actions to scene
    end
    @state.load_scene_actions(scene)
    @main_view.add_action(scene.actions)
    #update id
    @id = scene.identifier
    @state.currentscene = scene_index
    close_toybox
    grab
  end

  # def add_all_toy_actions(toy)
  #   toy.actions.each do |action|
  #     @main_view.add_action(action)
  #     if action[:effect_type] == :create_new_toy
  #       add_all_toy_actions((@state.toys.select{ |altToy| altToy.identifier == action[:effect_param][:id]}).first)
  #     end
  #   end
  # end

  # Called when the view disappears.
  def viewWillDisappear(animated)
    super
    # collect the scene information to pass on to the play view controller
    save_scene

    #@play_view_controller.update_play_scene
  end

  def refresh
    @main_view.setNeedsDisplay
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
    #@main_view.setup_for_new
    @id = rand(2**60).to_s
    @main_view.clear

  end

end