class SceneCreatorViewController < UIViewController

  include CreatorViewControllerModule

  MODES = [:scene, :toy]

  attr_writer :toybox, :play_view_controller
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
    puts "Show the scene box"
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
    close_toybox
    grab
  end

  # Called when the view disappears.
  def viewWillDisappear(animated)
    super
    # collect the scene information to pass on to the play view controller
    @state.scenes = [@main_view.gather_scene_info] # only one scene while developing
    @play_view_controller.update_play_scene
  end


end