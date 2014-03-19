class ToyCreatorViewController < UIViewController

  include CreatorViewControllerModule

  MODES = [:toy]

  def loadView # preferable to viewDidLoad because not using xib
    # Can call super this time as super is not UIViewController
    self.view = UIView.alloc.initWithFrame(@bounds)
    location_of_play = [95, 0]
    size_of_play = [@bounds.size.width - 190, @bounds.size.height]
    @main_view = ToyCreatorView.alloc.initWithFrame([location_of_play, size_of_play])
    @main_view.add_delegate(self)
    view.addSubview(@main_view)
    setup_colour_buttons
    @current_colour_view.current_colour_image = Swatch.images['blue']
    @main_view.current_colour = UIColor.blueColor
    setup_tool_buttons
    setup_mode_buttons(MODES)
    @tool_buttons[:squiggle].selected = true # the default
    setup_label(Language::TOY_MAKER)
  end

  # Clears the view and resets to create a new toy.
  def start_new_toy
    @main_view.setup_for_new
  end


  # Sets up to start a new toy and closes the toy box.
  def close_toybox
    start_new_toy
    dismissModalViewControllerAnimated(true, completion: nil)
  end

  # Show the toy box.
  def toy
    toy_parts = @main_view.gather_toy_info

    unless toy_parts.nil?
      # get random identifier
      id = rand(2**60).to_s
      toy = ToyTemplate.new(toy_parts, id) #, image)
      @state.add_toy(toy)
    end

    toybox_view_controller = ToyBoxViewController.alloc.initWithNibName(nil, bundle: nil)
    toybox_view_controller.state = @state

    toybox_view_controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical
    toybox_view_controller.modalPresentationStyle = UIModalPresentationPageSheet
    toybox_view_controller.delegate = self
    presentViewController(toybox_view_controller, animated: true, completion: nil)
    #toybox_view_controller.setup_toys(@state.toys)
  end

  # Called when a toy image is clicked on in the toy box view.
  def drop_toy(toy_button)
    puts "should edit a toy"
  end

end