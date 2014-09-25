# Super class of scene and toy creator view controllers.
# Sort of an abstract class - can't be created directly
# Now a module
module CreatorViewControllerModule

  #puts "loaded"

  TOOLS = [:grab, :squiggle, :line, :circle, :undo, :redo, :trash,:clear]
  #COLOURS = ['black', 'blue', 'brown', 'cyan', 'green', 'magenta', 'orange', 'purple', 'red', 'yellow', 'white']

  attr_writer :state

  #def loadView # preferable to viewDidLoad because not using xib
  #  # Do not call super.
  #  #self.modalPresentationStyle = UIModalPresentationCurrentContext
  #  setup_colour_buttons
  #  setup_tool_buttons
  #  #setup_mode_buttons
  #end

  # code to enable orientation changes
  #def supportedInterfaceOrientations
  #  UIInterfaceOrientationMaskPortrait
  #end

  #def shouldAutorotateToInterfaceOrientation(orientation)
  #  if orientation == UIDeviceOrientationPortraitUpsideDown || orientation == UIDeviceOrientationPortrait
  #    return false
   # end
  #  true
  #end

  def viewDidAppear(animated)
    super
    @main_view.reset_undo
  end

  def viewDidDisappear(animated)
    super
    @state.save
  end

  def setup_label(name)
    view_label = UILabel.alloc.initWithFrame([[0, 0], [@main_view.bounds.size.width, 20]])
    view_label.textColor = UIColor.whiteColor
    view_label.text = name
    view_label.textAlignment = NSTextAlignmentCenter
    @main_view.label = view_label
    @main_view.addSubview(view_label)
  end

  def bounds_for_view=(bounds)
    @bounds = bounds
  end

  # Add the colour buttons.
  def setup_colour_buttons
    @current_colour_view = CurrentColourView.alloc.initWithFrame([[0, 0], [95, 95]])
    view.addSubview(@current_colour_view)

    colour_view = EdgeView.alloc.init
    # need to catch draw events starting in this area
    colour_view.creator_view = @main_view

    def colour_view.sizeThatFits(size)
      width, height = 0, 0
      subviews.each do |subview|
        sub_width, sub_height = subview.frame.size.width, subview.frame.size.height
        width = sub_width if width < sub_width
        height += 10.0 + sub_height
      end
      width += 10.0
      height += 10.0
      CGSizeMake(width, height)
    end

    position = [10, 10]
    Swatch::COLOURS.each do |colour_name|
      button = setup_button(colour_name, position, colour_view)
      position[1] += CGRectGetHeight(button.frame) + 10
    end
    colour_view.sizeToFit
    colour_scrollview = UIScrollView.alloc.initWithFrame(CGRectMake(0, 95, 95, @bounds.size.height - 95))
    colour_scrollview.backgroundColor = UIColor.darkGrayColor
    colour_scrollview.setContentSize(colour_view.bounds.size)
    colour_scrollview.addSubview(colour_view)
    view.addSubview(colour_scrollview)
  end

  def name_for_label(name)
    case name
      when :grab
        Language::GRAB
      when :squiggle
        Language::SQUIGGLE
      when :line
        Language::LINE
      when :circle
        Language::CIRCLE
      when :undo
        Language::UNDO
      when :redo
        Language::REDO
      when :trash
        Language::TRASH
      when :clear
        Language::CLEAR
    end
  end

  # Add the tool control buttons.
  def setup_tool_buttons
    tool_view = EdgeView.alloc.init
    tool_view.creator_view = @main_view
    tool_view.backgroundColor = UIColor.darkGrayColor

    def tool_view.sizeThatFits(size)
      width, height = 0, 0
      subviews.each do |subview|
        sub_width, sub_height = subview.frame.size.width, subview.frame.size.height
        width = sub_width if width < sub_width
        height += 5.0 + sub_height
      end
      CGSizeMake(width, height)
    end
    # The :trash button should only be available when :grab is the mode.
    # The :undo and :redo buttons should only be available at appropriate times.
    # All other buttons should act like radio buttons - only one of :grab, :squiggle, :line and :circle at a time.
    @tool_buttons = {}
    position = [10, 10]
    TOOLS.each do |tool_name|
      button = setup_button(tool_name, position, tool_view)
      @tool_buttons[tool_name] = button
      # then add the label underneath
      yPos = button.frame.origin.y + button.frame.size.height
      position[1] += CGRectGetHeight(button.frame)
      label = UILabel.alloc.initWithFrame([[0, position[1]], [95, 14]])
      label.font = UIFont.systemFontOfSize(12)
      label.textColor = UIColor.whiteColor
      label.text = name_for_label(tool_name)
      label.textAlignment = NSTextAlignmentCenter
      tool_view.addSubview(label)
      position[1] += CGRectGetHeight(label.frame) + 5
    end
    @tool_buttons[:undo].enabled = false
    @tool_buttons[:redo].enabled = false
    @tool_buttons[:trash].enabled = false # need to turn on when something is selected
    @main_view.trash_button = @tool_buttons[:trash]
    tool_view.sizeToFit
    tool_scrollview = UIScrollView.alloc.initWithFrame(CGRectMake(@bounds.size.width - 95, 0, 95, @bounds.size.height))
    tool_scrollview.backgroundColor = UIColor.darkGrayColor
    tool_scrollview.setContentSize(CGSizeMake(tool_view.bounds.size.width,tool_view.bounds.size.height-20))
    tool_scrollview.addSubview(tool_view)
    view.addSubview(tool_scrollview)
  end

  # Add the mode buttons
  def setup_mode_buttons(modes)
    @mode_view = UIView.alloc.initWithFrame(
        CGRectMake(95, 0, 95 * modes.length, 95)) # @bounds.size.width - 95 - 85, @bounds.size.height - 95, 190, 95))
    position = [10, 10]
    modes.each do |mode_name|
      button = setup_button(mode_name, position, @mode_view)
      position[0] += CGRectGetWidth(button.frame) + 10
    end
    view.addSubview(@mode_view)
  end

  def setup_button(image_name, position, super_view)
    button = UIButton.buttonWithType(UIButtonTypeCustom)
    button.setImage(UIImage.imageNamed(image_name), forState: UIControlStateNormal)
    button.setImage(UIImage.imageNamed(image_name + '_selected'), forState: UIControlStateSelected) rescue puts 'rescued'
    button.sizeToFit
    button.frame = [position, button.frame.size]
    button.addTarget(self, action: image_name, forControlEvents: UIControlEventTouchUpInside)
    super_view.addSubview(button)
    button
  end

  # Changes the selected button to the named one.
  def select_button(name)
    @tool_buttons.each do |key, value|
      value.selected = (key == name)
    end
  end

  # fire config of the scene
  def config
    content = SceneConfigPopoverViewController.alloc.initWithNibName(nil, bundle: nil)
    content.setTitle("Scene Properties")
    content.delegate = self
    content.enterState(@state)
    show_popover(content)
  end

  def show_popover(content)
    @popover = UIPopoverController.alloc.initWithContentViewController(content)
    @popover.delegate = self
    viewy = self.view
    frame = CGRectMake(view.bounds.size.width/3,0,0,220)
    @popover.presentPopoverFromRect(frame , inView: viewy, permittedArrowDirections: UIPopoverArrowDirectionLeft | UIPopoverArrowDirectionRight, animated:true)
  end

  def close_popover
    if not @popover.nil?
      @popover_type = nil
      @popover.dismissPopoverAnimated(true)
    end
    disableButtons
    hide_sides
  end

  # Change mode to grab.
  def grab
    @main_view.current_tool = :grab
    select_button(:grab)
  end

  # Change mode to squiggle.
  def squiggle
    @main_view.current_tool = :squiggle
    select_button(:squiggle)
  end

  # Change mode to line.
  def line
    @main_view.current_tool = :line
    select_button(:line)
  end

  # Change mode to circle.
  def circle
    @main_view.current_tool = :circle
    select_button(:circle)
  end

  # Trash any selected stroke.
  def trash
    @main_view.remove_selected
  end

  def clear
    @id = rand(2**60).to_s
    @main_view.clear
  end

  # Called when undo state might change.
  def can_undo(possible)
    @tool_buttons[:undo].enabled = possible
  end

  # Called when redo state might change.
  def can_redo(possible)
    @tool_buttons[:redo].enabled = possible
  end

  # Undo the last stroke action.
  def undo
    @main_view.undo
  end

  # Redo the last stroke action.
  def redo
    @main_view.redo
  end

  def black
    @main_view.current_colour = UIColor.blackColor
    @current_colour_view.current_colour_image = Swatch.images['black']
  end

  def blue_colour
    @main_view.current_colour = UIColor.blueColor
    @current_colour_view.current_colour_image = Swatch.images['blue_colour']
  end

  def brown
    @main_view.current_colour = UIColor.brownColor
    @current_colour_view.current_colour_image = Swatch.images['brown']
    #view.current_colour = UIColor.colorWithRed(107.0/255.0, green: 66.0/255.0, blue: 0.0, alpha: 1.0)
  end

  def cyan
    @main_view.current_colour = UIColor.colorWithRed(0.0, green: 209.0/255.0, blue: 251.0/255.0, alpha: 1.0)
    @current_colour_view.current_colour_image = Swatch.images['cyan']
    #view.current_colour = UIColor.cyanColor
  end

  def green_colour
    @main_view.current_colour = UIColor.colorWithRed(0.0, green: 169.0/255.0, blue: 0.0, alpha: 1.0)
    @current_colour_view.current_colour_image = Swatch.images['green_colour']
    #view.current_colour = UIColor.greenColor
  end

  def magenta
    @main_view.current_colour = UIColor.colorWithRed(229.0/255.0, green: 57.0/255.0, blue: 230.0/255.0, alpha: 1.0)
    @current_colour_view.current_colour_image = Swatch.images['magenta']
    #view.current_colour = UIColor.magentaColor
  end

  def orange
    @main_view.current_colour = UIColor.orangeColor
    @current_colour_view.current_colour_image = Swatch.images['orange']
  end

  def purple
    @main_view.current_colour = UIColor.purpleColor
    @current_colour_view.current_colour_image = Swatch.images['purple']
  end

  def red_colour
    @main_view.current_colour = UIColor.redColor
    @current_colour_view.current_colour_image = Swatch.images['red_colour']
  end

  def yellow
    @main_view.current_colour = UIColor.yellowColor
    @current_colour_view.current_colour_image = Swatch.images['yellow']
  end

  def white
    white = UIColor.colorWithRed(1.0, green: 1.0, blue: 1.0, alpha: 1.0) # due to a bug in UIColor.whiteColor
    @main_view.current_colour = white
    @current_colour_view.current_colour_image = Swatch.images['white']
  end

end

class Swatch

  COLOURS = ['black', 'blue_colour', 'brown', 'cyan', 'green_colour', 'magenta', 'orange', 'purple', 'red_colour', 'yellow', 'white']

  def self.images
    if @images.nil?
      @images = {}
      COLOURS.each do |colour|
        @images[colour] = UIImage.imageNamed('selected_' + colour)
      end
    end
    @images
  end

end