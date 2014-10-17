# A drag action is usually associated with an effect.
# e.g. dragging a toy here probably means apply a force in the direction of the drag.
class CreateActionViewController < UIViewController

  #, :delegate
  attr_writer :toybox, :new_toy, :selected, :scene_creator_view_controller

  def loadView # preferable to viewDidLoad because not using xib
    # Do not call super.
    action_over_view = UIView.alloc.init
    self.view = action_over_view
    @main_view = @scene_creator_view_controller.main_view
    @main_view.mode = :create_new_toy
    view.addSubview(@main_view)
    @main_view.change_label_text_to(Language::CREATE_ADDER)
    @main_view.secondary_selected = @selected
    @main_view.selected = @new_toy

    command_label = UILabel.alloc.initWithFrame([[0, @bounds.size.height], [@bounds.size.width, 768 - @bounds.size.height]])
    command_label.backgroundColor = Constants::GOLD
    command_label.text = Language::DRAG_CREATE_TOY
    command_label.textAlignment = NSTextAlignmentCenter
    view.addSubview(command_label)

    setup_random_button

    setup_done
    @main_view.setNeedsDisplay
  end

  def setup_random_button
    @random_view = UIView.alloc.initWithFrame(
        CGRectMake(@bounds.size.width-190-95, 0, 95, 95)) # @bounds.size.width - 95 - 85, @bounds.size.height - 95, 190, 95))
    position = [10, 10]

    button = setup_button(:random, position, @random_view)
    position[0] += CGRectGetWidth(button.frame) + 10

    view.addSubview(@random_view)
  end

  def setup_done
    @mode_view = UIView.alloc.initWithFrame(
        CGRectMake(@bounds.size.width-190, 0, 95, 95)) # @bounds.size.width - 95 - 85, @bounds.size.height - 95, 190, 95))
    position = [10, 10]

    button = setup_button(:done, position, @mode_view)
    position[0] += CGRectGetWidth(button.frame) + 10

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


  def done
    # newToy = ToyInScene.new(@state.toys[toy_index], 1.0, true)
    # @main_view.add_toy(newToy)
    @main_view.end_create_toy
  end

  def random
    puts "random location is set"
    @main_view.end_create_toy(true)
  end

  def bounds_for_view=(bounds)
    @bounds = bounds
  end

end