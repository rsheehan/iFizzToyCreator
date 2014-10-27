class ToyCreatorViewController < UIViewController
  include CreatorViewControllerModule
  MODES = [:toy, :new]
  
  def loadView # preferable to viewDidLoad because not using xib
    # Can call super this time as super is not UIViewController
    self.view = UIView.alloc.initWithFrame(@bounds)
    self.view.alpha = 0.0
    self.view.accessibilityLabel = 'toyView'
    location_of_play = [95, 0]
    size_of_play = [@bounds.size.width - 190, @bounds.size.height]
    @main_view = ToyCreatorView.alloc.initWithFrame([location_of_play, size_of_play])
    @main_view.add_delegate(self)
    view.addSubview(@main_view)
    
    setup_colour_buttons
    @current_colour_view.current_colour_image = Swatch.images['blue_colour']
    @main_view.current_colour = UIColor.blueColor
    setup_tool_buttons
    setup_mode_buttons(MODES)
    @tool_buttons[:squiggle].selected = true # the default
    setup_label(Language::TOY_MAKER)
    #assign an id to the toy being made
    @id = rand(2**60).to_s

  end

  def viewDidAppear(animated)
    self.view.alpha = 0.0
    UIView.animateWithDuration(1.0, animations: proc{
      self.view.alpha=1.0
    })
    # UIView.transitionFromView(@temporaryView, toView:@main_view, duration:0.5, options:UIViewAnimationOptionTransitionCrossDissolve, completion: nil)
  end

  # Clears the view and resets to create a new toy.
  def start_new_toy
    @main_view.setup_for_new
    @id = rand(2**60).to_s
  end

  def new
    save_toy
    start_new_toy
  end

  # Sets up to start a new toy and closes the toy box.
  def close_toybox
    dismissModalViewControllerAnimated(true, completion: nil)
  end

  # Show the toy box.
  def toy
    save_toy
    toybox_view_controller = ToyBoxViewController.alloc.initWithNibName(nil, bundle: nil)
    toybox_view_controller.state = @state

    toybox_view_controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical
    toybox_view_controller.modalPresentationStyle = UIModalPresentationPageSheet
    toybox_view_controller.delegate = self
    presentViewController(toybox_view_controller, animated: true, completion: nil)
  end

  # Called when a toy image is clicked on in the toy box view.
  def drop_toy(toy_button)
    centre = CGPointMake((@bounds.size.width-190)/2, @bounds.size.height/2)
    #clear screen
    @main_view.setup_for_new
    #get toy
    toy = @state.toys[toy_button]
    #draw toy
    toy.parts.each do |part|
      case part
        when CirclePart
          @main_view.add_stroke(CircleStroke.new(((part.position/ToyTemplate::IMAGE_SCALE)+ centre), part.radius/ ToyTemplate::IMAGE_SCALE, part.colour, 1))
        when PointsPart
          points = part.points.map { |p| p/ToyTemplate::IMAGE_SCALE+centre }
          @main_view.add_stroke(LineStroke.new(points, part.colour, ToyTemplate::TOY_LINE_SIZE))
        else
      end
    end
    @main_view.setNeedsDisplay
    #update id
    @id = toy.identifier
    dismissModalViewControllerAnimated(true, completion: nil)
  end

  def viewWillDisappear(animated)
    super
    save_toy
  end

  def save_toy
    puts "save toy"
    toy_parts = @main_view.gather_toy_info
    unless toy_parts.nil?
      toy = ToyTemplate.new(toy_parts, @id)
      @state.add_toy(toy)
    end
  end

  def clear
    @main_view.clear
  end

end