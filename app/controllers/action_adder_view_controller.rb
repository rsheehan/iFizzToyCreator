# The view controller when adding actions.

class ActionAdderViewController < UIViewController

  # Actions are hashes with the following keys.
  ACTIONS = [:touch, :timer, :collision, :shake, :score_reaches, :when_created, :loud_noise, :toy_touch]
  EFFECTS = [:apply_force, :explosion, :apply_torque, :create_new_toy, :delete_effect, :score_adder, :play_sound, :text_bubble, :scene_shift, :move_towards,:move_away, :send_message ]
  MODES = [:background]
  FORCE_SCALE = 250
  EXPLODE_SCALE = 80
  ROTATION_SCALE = 2
  DELETE_FADE_TIME = 0.4 # seconds

  TOP = 10
  MIDDLE = 281
  BOTTOM = 552
  LEFT = 10
  EMPTY_ICON_INSET = UIScreen.mainScreen.scale != 1.0 ? 20 : 10

  attr_writer :state, :scene_creator_view_controller, :back_from_modal_view
  attr_accessor :tab_bar

  # TODO: undo/redo for placing, moving, resizing toys
  # Make sure that a list of added toys is maintained. These are removed when
  # reverting to SceneCreatorViewController or PlayViewController.

  def loadView # preferable to viewDidLoad because not using xib
    action_over_view = UIView.alloc.init
    self.view = action_over_view
    self.view.alpha = 0.0
    location_of_action = [95, 0]
    size_of_action = [@bounds.size.width - 190, @bounds.size.height]
    @button_toys = {}
    setup_sides
    @main_view = @scene_creator_view_controller.main_view
    show_sides
  end

  def bounds_for_view=(bounds)
    @bounds = bounds
  end

  def background
    p "scene action pressed"
    start_scene_action_flow
  end

  def name_for_label_action(label)
    case label
      when :background
        return "scene action"
    end
  end

  def viewWillDisappear(animated)
    p "view disappears"
    close_popover
  end

  def save_scene

  end

  def viewDidAppear(animated)
    p "view did appear"

    if @main_view == nil
      @main_view = @scene_creator_view_controller.main_view
    end
    if @main_view == nil
      moveToSceneBar
    else
      if @main_view.numberOfElements <= 1
        moveToSceneBar
      end

      #self.view.alpha = 0.0
      @button_toys = {}
      @main_view.change_label_text_to(Language::ACTION_ADDER)
      @main_view.add_delegate(self)
      @main_view.mode = :toys_only
      view.addSubview(@main_view)
      @main_view.updateToyInScene
      @main_view.setNeedsDisplay

      super
      if not @selected_toy.nil? and not @back_from_modal_view
        start_action_flow
      end

      #UIView.animateWithDuration(0.5, animations: proc{
        self.view.alpha=1.0
      #})
    end
    show_sides
  end

  def moveToSceneBar
    if tab_bar != nil
      tab_bar.selectedIndex = 2
    end
  end

  def moveToToyBar(toyTemplate)
    if tab_bar != nil
      tab_bar.selectedIndex = 1
      tab_bar.selectToyTemplateToEdit(toyTemplate)
    end
  end

  def reload_button_image_hash
    @button_toys = {}
    draw_all_buttons
    if @state.currentscene == nil
      @state.currentscene = 0
    end

    if @state.scenes[@state.currentscene] != nil
      @state.scenes[@state.currentscene].toys.each do |toy|
        @state.return_toy_actions(toy).each do |action|
          if action[:action_type] == :button
            add_toy_to_button(toy.template,action[:action_param])
          end
        end
      end
    end
  end

  def state
    @state
  end


  def draw_all_buttons
    all_buttons = [@left_panel.subviews, @right_panel.subviews].flatten
    all_buttons.each do |button|
      draw_button(button)
    end
  end

  def draw_button(button)
    if @button_toys[button].nil?
      @button_toys[button] = []
    end
    button.setImage(get_btn_image_with_toys(@button_toys[button]), forState: UIControlStateNormal)
    button.setImage(get_sel_btn_image_with_toys(@button_toys[button]), forState: UIControlStateSelected) rescue puts 'rescued'
  end

  # The sides are left for user interactions to the running scenes
  def setup_sides
    @left_panel = UIView.alloc.initWithFrame(CGRectMake(0, 0, 95, @bounds.size.height))
    @left_panel.setBackgroundColor(UIColor.grayColor)
    @left_top_button =    setup_game_button([LEFT, TOP], @left_panel)
    @left_middle_button = setup_game_button([LEFT, MIDDLE], @left_panel)
    @left_bottom_button = setup_game_button([LEFT, BOTTOM], @left_panel,)
    view.addSubview(@left_panel)
    @right_panel = UIView.alloc.initWithFrame(CGRectMake(@bounds.size.width - 95, 0, 95, @bounds.size.height))
    @right_panel.setBackgroundColor(UIColor.grayColor)
    @right_top_button =    setup_game_button([LEFT, TOP], @right_panel)
    @right_middle_button = setup_game_button([LEFT, MIDDLE], @right_panel)
    @right_bottom_button = setup_game_button([LEFT, BOTTOM], @right_panel)
    view.addSubview(@right_panel)
    hide_sides
  end

  def show_sides
    reload_button_image_hash
    @left_panel.hidden = false
    @right_panel.hidden = false
  end

  def hide_sides
    #@left_panel.hidden = true
    #@right_panel.hidden = true
  end

  def setup_game_button(position, panel)
    button = UIButton.buttonWithType(UIButtonTypeCustom)
    button.setImage(UIImage.imageNamed('side_button'), forState: UIControlStateNormal)
    button.setImage(UIImage.imageNamed('side_button_selected'), forState: UIControlStateHighlighted)
    button.sizeToFit
    button.frame = [position, button.frame.size]
    @button_toys[button] = []
    button.addTarget(self, action: 'selected_button:', forControlEvents: UIControlEventTouchUpInside)
    button.enabled = false
    panel.addSubview(button)
    button
  end

  def disableButtons
    @left_bottom_button.enabled = false
    @left_middle_button.enabled = false
    @left_top_button.enabled = false
    @right_bottom_button.enabled = false
    @right_middle_button.enabled = false
    @right_top_button.enabled = false
  end

  def enableButtons
    @left_bottom_button.enabled = true
    @left_middle_button.enabled = true
    @left_top_button.enabled    = true
    @right_bottom_button.enabled = true
    @right_middle_button.enabled = true
    @right_top_button.enabled    = true
  end

  def setup_button(image_name, position, super_view)
    button = UIButton.buttonWithType(UIButtonTypeCustom)
    button.setImage(UIImage.imageNamed(image_name), forState: UIControlStateNormal)
    button.setImage(UIImage.imageNamed(image_name + '_selected'), forState: UIControlStateSelected) rescue puts 'rescued'
    button.sizeToFit
    button.frame = [position, button.frame.size]
    button.addTarget(self, action: image_name, forControlEvents: UIControlEventTouchUpInside)
    button.enabled = false
    super_view.addSubview(button)
    button
  end

  def show_actions
    p 'SHOW ACTIONS'
    if(@selected_toy)
      #show modal with view of all associated actions and effects
      action_list_view_controller = ActionListViewController.alloc.initWithNibName(nil, bundle: nil)
      action_list_view_controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical
      action_list_view_controller.modalPresentationStyle = UIModalPresentationFormSheet
      action_list_view_controller.delegate = self
      action_list_view_controller.state = @state
      action_list_view_controller.scene_creator_view_controller = @scene_creator_view_controller
      action_list_view_controller.selected = @selected_toy
      presentViewController(action_list_view_controller, animated: true, completion: nil)
    end
  end

  def show_properties
    p 'Show properties'
    if(@selected_toy)
      prop_list_view_controller = PropertyListViewController.alloc.initWithNibName(nil, bundle: nil)
      prop_list_view_controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical
      prop_list_view_controller.modalPresentationStyle = UIModalPresentationFormSheet
      prop_list_view_controller.delegate = self
      prop_list_view_controller.state = @state
      prop_list_view_controller.scene_creator_view_controller = @scene_creator_view_controller
      prop_list_view_controller.selected = @selected_toy
      presentViewController(prop_list_view_controller, animated: true, completion: nil)
    end
  end

  def enable_show_mode_buttons(enable)
    if @show_properties_btn
      @show_actions_btn.enabled = enable;
      @show_properties_btn.enabled = enable;
    end
  end

  def close_touch_view_controller
    dismissModalViewControllerAnimated(false, completion: nil)
    enable_show_mode_buttons(false)
  end

  def selected_toy=(toy)
    @selected_toy = toy
    enable_show_mode_buttons(@selected_toy)
  end

  def get_action
    if @action_button_name
      action_type = :button
      action_param = @action_button_name
    elsif @repeat_time_secs
      action_type = :timer
      action_param = [@repeat_time_secs]
    elsif @colliding_toy
      action_type = :collision
      action_param = @colliding_toy.identifier
    elsif @loud_noise
      action_type = :loud_noise
      action_param = nil
    elsif @when_created
      action_type = :when_created
      action_param = [@after_created_time_secs]
    elsif @shake
      action_type = :shake
      action_param = nil
    elsif @score_reaches
      action_type = :score_reaches
      action_param = [@score_reaches]
    elsif @toy_touch
      action_type = :toy_touch
      action_param = nil
    elsif @message_receive
      action_type = :receive_message
      action_param = @message_receive.to_s
    else
      action_type = :unknown
      action_param = :unknown
    end
    reset_action_params
    return action_type, action_param
  end

  def reset_action_params
    @action_button_name = nil
    @repeat_time_secs = nil
    @after_created_time_secs = nil
    @colliding_toy = nil
    @loud_noise = nil
    @when_created = nil
    @shake = nil
    @score_reaches = nil
    @toy_touch = nil
    @message_receive = nil
  end

  # Gets the force information for the actions effect.
  # When this is received the action info is complete.
  # Here force_vector is actually CGPoint
  def force=(force_vector)
    action_type, action_param = get_action
    #puts "Force: X: " + force_vector.x.to_s + ", Y: " + force_vector.y.to_s
    effect_type = :apply_force
    effect_param = force_vector * FORCE_SCALE
    create_action_effect(@selected_toy, action_type, action_param, effect_type, effect_param)
    #remove shadows from other colliding toy if collision action
  end

  def rotation=(force)
    action_type, action_param = get_action
    #puts "action type = #{action_type} and param = #{action_param}"
    effect_type = :apply_torque
    if(force != Constants::RANDOM_HASH_KEY)
      effect_param = force * ROTATION_SCALE
    else
      effect_param = force
    end

    create_action_effect(@selected_toy, action_type, action_param, effect_type, effect_param)
    #remove shadows from other colliding toy if collision action
  end

  def explosion=(force)
    action_type, action_param = get_action
    effect_type = :explosion
    if force != Constants::RANDOM_HASH_KEY
      effect_param = force * EXPLODE_SCALE
    else
      effect_param = force
    end
    create_action_effect(@selected_toy, action_type, action_param, effect_type, effect_param)

  end

  def main_view
    @main_view
  end

  def create_new_toy=(args)
    action_type, action_param = get_action
    effect_type = :create_new_toy
    effect_param = args
    create_action_effect(@selected_toy, action_type, action_param, effect_type, effect_param)
  end

  def drop_scene(scene_index)
    close_toybox
    scene = @state.scenes[scene_index]
    action_type, action_param = get_action
    effect_type = :scene_shift
    effect_param = scene.identifier
    create_action_effect(@selected_toy, action_type, action_param, effect_type, effect_param)
  end

  # This is where we create the action/effect.
  def create_action_effect(toy, action_type, action_param, effect_type, effect_param)
    thisSceneID = @main_view.scene_drop_id.to_s #"2991984"
    puts "ACTION on toy #{toy.template.identifier}: when #{action_type}(#{action_param}) do #{effect_type}(#{effect_param})"
    action = {toy: toy.template.identifier, action_type: action_type, action_param: action_param,
              effect_type: effect_type, effect_param: effect_param, scene: thisSceneID}
    @scene_creator_view_controller.main_view.add_action(action)
    toy.template.actions << action
    #if button - add image to button
    if action_type == :button
      add_toy_to_button(toy,action_param)
    end
    #save actions
    @main_view.secondary_selected = nil
    @main_view.setNeedsDisplay
    #@state.save
  end

  def add_toy_to_button(toy, button_name)
    #puts 'adding toy to '+ button_name.to_s
    if toy.is_a?(ToyInScene)
      toy = toy.template
    end

    button = nil
    case button_name
      when :left_top, 'left_top'
        button = @left_top_button
      when :left_middle, 'left_middle'
        button = @left_middle_button
      when :left_bottom, 'left_bottom'
        button = @left_bottom_button
      when :right_top, 'right_top'
        button = @right_top_button
      when :right_middle, 'right_middle'
        button = @right_middle_button
      when :right_bottom, 'right_bottom'
        button = @right_bottom_button
      else
        puts 'Idk what button that was..'
    end
    if @button_toys[button].nil?
      @button_toys[button] = []
    end
    @button_toys[button].delete_if {|t| t.identifier == toy.identifier }
    @button_toys[button] << toy
    #update image
    button.setImage(get_btn_image_with_toys(@button_toys[button]), forState: UIControlStateNormal)
    button.setImage(get_sel_btn_image_with_toys(@button_toys[button]), forState: UIControlStateSelected) rescue puts 'rescued'
  end

  def get_btn_image_with_toys(toys)
    image = UIImage.imageNamed('side_button')
    UIGraphicsBeginImageContext(image.size)
    image.drawInRect(CGRectMake(0,0,image.size.width,image.size.height))
    context = UIGraphicsGetCurrentContext()

    #show all toys equally spaced
    toys.each_with_index { |toy, index|
      if index < 2 or (index == 2 and toys.size == 3)
        rect = CGRectMake(EMPTY_ICON_INSET, EMPTY_ICON_INSET+index*(image.size.height-2*EMPTY_ICON_INSET)/[toys.size,3].min, image.size.width-2*EMPTY_ICON_INSET, (image.size.height-2*EMPTY_ICON_INSET)/[toys.size,3].min)
        aspect = toy.image.size.width / toy.image.size.height
        if (rect.size.width / aspect <= rect.size.height)
          offset = rect.size.height
          rect.size = CGSizeMake(rect.size.width, rect.size.width/aspect)
          #make sure image is centered in height
          offset = (offset - rect.size.width/aspect)/2
          rect.origin = CGPointMake(rect.origin.x, rect.origin.y+offset)
        else
          offset = rect.size.width
          rect.size = CGSizeMake(rect.size.height * aspect, rect.size.height)
          #make sure image is centered in width
          offset = (offset - rect.size.height*aspect)/2
          rect.origin = CGPointMake(rect.origin.x+offset, rect.origin.y)
        end
        toy.image.drawInRect(rect)

      elsif index ==  2 and toys.size > 3
        #draw ... in third rect?
        rect = CGRectMake(0, 2*image.size.height/[toys.size,3].min, image.size.width, image.size.height/[toys.size,3].min)
        puts 'img size = '+image.size.width.to_s+ ", "+image.size.height.to_s
        puts 'draw dots in - 0,'+ (2*image.size.height/[toys.size,3].min).to_s+',' +image.size.width.to_s+','+ (image.size.height/[toys.size,3].min).to_s
        draw_dots_in_rect(context, rect)
      end
    }

    newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    newImage
  end

  def draw_dots_in_rect(context, rect)
    height = rect.size.height
    width = rect.size.width
    x = rect.origin.x
    y = rect.origin.y
    centers = [ CGPointMake(x+width/4,y+height/2),CGPointMake(x+2*width/4,y+height/2),CGPointMake(x+3*width/4,y+height/2)]
    radius = [height/4, width/16].min

    centers.each do |center|
      rectangle = CGRectMake(center.x - radius, center.y - radius, radius*2, radius*2)
      CGContextSetFillColorWithColor(context,UIColor.blackColor.CGColor)
      CGContextAddEllipseInRect(context, rectangle)
      CGContextFillPath(context)
    end

  end

  def get_sel_btn_image_with_toys(toys)
    image = UIImage.imageNamed('side_button_selected')
    UIGraphicsBeginImageContext(image.size)
    image.drawInRect(CGRectMake(0,0,image.size.width,image.size.height))
    context = UIGraphicsGetCurrentContext()

    #show all toys equally spaced
    toys.each_with_index { |toy, index|
      if index < 2 or (index == 2 and toys.size == 3)
        rect = CGRectMake(0, index*image.size.height/[toys.size,3].min, image.size.width, image.size.height/[toys.size,3].min)
        toy.image.drawInRect(rect)
      elsif index ==  2
        #draw ... in third rect?
        rect = CGRectMake(0, 3*image.size.height/[toys.size,3].min, image.size.width, image.size.height/[toys.size,3].min)
        draw_dots_in_rect(context, rect)
      end
    }

    newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    newImage
  end

  # Called when undo state might change.
  def can_undo(possible)
    #@tool_buttons[:undo].enabled = possible
  end

  # Called when redo state might change.
  def can_redo(possible)
    #@tool_buttons[:redo].enabled = possible
  end

  # Closes any modal view.
  def close_modal_view (animation = false)
    dismissModalViewControllerAnimated(animation, completion: nil)
  end

  # Called when the view disappears.
  def viewWillDisappear(animated)
    super
  end

  # draw label below icons
  def name_for_label(name)
    case name
      when :touch
        Language::TOUCH
      when :collision
        Language::COLLISION
      when :timer
        Language::REPEAT
      when :hold
        Language::HOLD
      when :shake
        Language::SHAKE
      when :when_created
        Language::WHEN_CREATED
      when :loud_noise
        Language::LOUD_NOISE
      when :toy_touch
        Language::TOY_TOUCH
      when :score_reaches
        Language::SCORE_REACHES
      when :apply_force
        Language::FORCE
      when :apply_torque
        Language::ROTATION
      when :explosion
        Language::EXPLOSION
      when :create_new_toy
        Language::CREATE_NEW_TOY
      when :delete_effect
        Language::DELETE
      when :score_adder
        Language::SCORE_ADDER
      when :play_sound
        Language::PLAY_SOUND
      when :text_bubble
        Language::TEXT_BUBBLE
      when :scene_shift
        Language::SCENE_SHIFT
      when :move_towards
        Language::MOVE_TOWARDS_OTHERS
      when :move_away
        Language::MOVE_AWAY_OTHERS
      else
        :unknown
    end
  end

  def drop_toy(toy)
    drag_action_view_controller = CreateActionViewController.alloc.initWithNibName(nil, bundle: nil)
    drag_action_view_controller.bounds_for_view = @bounds
    drag_action_view_controller.modalPresentationStyle = UIModalPresentationFullScreen
    drag_action_view_controller.selected = @selected_toy
    drag_action_view_controller.new_toy = ToyInScene.new(@state.toys[toy])
    drag_action_view_controller.scene_creator_view_controller = @scene_creator_view_controller
    dismissViewControllerAnimated(true, completion: lambda { presentViewController(drag_action_view_controller, animated: false, completion: nil)})
  end

  def close_toybox
    dismissModalViewControllerAnimated(true, completion: nil)
  end

  #==========
  # NEw Actions flow
  #=========
  def start_action_flow
    if @popover
      close_popover
    end
    @popoverStack = []
    reset_action_params

    if not @selected_toy.nil? and @state.scenes.size > 0
      content = ActionListPopoverViewController.alloc.initWithNibName(nil, bundle: nil)
      content.state = @state
      content.selected = @selected_toy
      content.delegate = self
      show_popover(content)
    end
  end

  def start_scene_action_flow
    if @popover
      close_popover
    end
    @popoverStack = []
    reset_action_params

    if @state.scenes.size > 0
      content = SceneActionListPopoverViewController.alloc.initWithNibName(nil, bundle: nil)
      content.state = @state
      @selected_toy = nil
      content.selected = nil
      content.scene = @state.scenes[@state.currentscene]
      content.delegate = self
      show_popover(content)
    end
  end

  def popoverController(pop, willRepositionPopoverToRect:rect, inView:view)
    puts "pop repo"
  end

  def reopen_action_flow
    #if there is a popover visible don't repoen?
    close_popover
    if @popoverStack.nil?
      start_action_flow
    elsif @popoverStack.size > 0
        content = @popoverStack.last
        @popover = UIPopoverController.alloc.initWithContentViewController(content)
        @popover.delegate = self
        x = @bounds.size.width/2 - 350/2
        frame = CGRectMake(0,0, x, 200)
        @popover.presentPopoverFromRect(frame , inView: self.view, permittedArrowDirections:  UIPopoverArrowDirectionLeft | UIPopoverArrowDirectionRight, animated:true)
    end
  end

  def action_flow_back
    close_popover
    #remove current popover from stack
    if @popoverStack.size > 0
      @popoverStack.pop
    end
    if @popoverStack.size > 0
      content = @popoverStack.last
      @popover = UIPopoverController.alloc.initWithContentViewController(content)
      @popover.delegate = self
      x = @bounds.size.width/2 - 350/2
      frame = CGRectMake(0,0, x, 200)
      @popover.presentPopoverFromRect(frame, inView: self.view, permittedArrowDirections:  UIPopoverArrowDirectionLeft | UIPopoverArrowDirectionRight, animated:true)
    end
  end

  def new_action
    close_popover
    #show new action popover
    content = CollectionViewPopoverViewController.alloc.initWithNibName(nil, bundle: nil)
    content.delegate = self
    content.mode = :actions
    show_popover(content)
  end

  def makeTrigger(type)
    reset_action_params
    close_popover
    case type
      when :touch
        @popover_type = :button
        content = ButtonSelectPopoverViewController.alloc.initWithNibName(nil, bundle: nil)
        content.delegate = self
        show_popover(content)
        show_sides
        # Minh: I have fixed the code below, this makes it crash in io8
        @popover.passthroughViews = [@left_panel, @right_panel]
        enableButtons
      when :timer
        @popover_type = :timer
        content = RepeatActionViewController.alloc.initWithNibName(nil, bundle: nil)
        content.delegate = self
        show_popover(content)
      when :collision
        content = CollectionViewPopoverViewController.alloc.initWithNibName(nil, bundle: nil)
        content.delegate = self
        content.mode = :toys
        content.state = @state
        content.setTitle(Language::TOUCH_COLLISION)
        show_popover(content)
      when :score_reaches
        @popover_type = :score_reaches
        content = NumericInputPopOverViewController.alloc.initWithNibName(nil, bundle: nil)
        content.setTitle(Language::CHOOSE_SCORE_REACHES)
        content.delegate = self
        show_popover(content)
      when :shake
        @shake = true
        show_effects_popover
      when :when_created
        @when_created = true
        @popover_type = :after_created
        content = RepeatActionViewController.alloc.initWithNibName(nil, bundle: nil)
        content.setLabel('Trigger after')
        content.delegate = self
        show_popover(content)
      when :loud_noise
        @loud_noise = true
        show_effects_popover
      when :toy_touch
        @toy_touch = @selected_toy
        show_effects_popover
      when :receive_message
        content = MessagePopOverViewController.alloc.initWithNibName(nil, bundle: nil)
        content.delegate = self
        content.setActionType("action")
        content.setTitle("What message do you want to send?")
        show_popover(content)
      else
        p 'unknow action'
    end
  end

  def selected_button(sender)
    close_popover
    disableButtons
    hide_sides
    case sender
      when @left_top_button
        @action_button_name = :left_top
      when @left_middle_button
        @action_button_name = :left_middle
      when @left_bottom_button
        @action_button_name = :left_bottom
      when @right_top_button
        @action_button_name = :right_top
      when @right_middle_button
        @action_button_name = :right_middle
      when @right_bottom_button
        @action_button_name = :right_bottom
      else
        puts 'Idk what button that was..'
    end
    show_effects_popover
  end

  def submit_number(number)
    case @popover_type
      when :score_reaches
        @score_reaches = number
      when :timer
        @repeat_time_secs = number
      when :after_created
        @after_created_time_secs = number
    end
    close_popover
    show_effects_popover
  end

  def show_effects_popover
    content = CollectionViewPopoverViewController.alloc.initWithNibName(nil, bundle: nil)
    content.delegate = self
    content.mode = :effects
    content.setTitle(Language::CHOOSE_EFFECT)
    show_popover(content)
  end

  def submit_receive_message(message)
    @message_receive = message
    close_popover
    show_effects_popover
  end

  def makeEffect(type)
    close_popover
    case type
      when :apply_force
        drag_action_view_controller = DragActionViewController.alloc.initWithNibName(nil, bundle: nil)
        drag_action_view_controller.bounds_for_view = @bounds
        drag_action_view_controller.modalPresentationStyle = UIModalPresentationFullScreen
        drag_action_view_controller.selected = @selected_toy
        drag_action_view_controller.scene_creator_view_controller = @scene_creator_view_controller
        presentViewController(drag_action_view_controller, animated: false, completion: nil)

      when :explosion
        explosion_action_view_controller = ExplosionActionViewController.alloc.initWithNibName(nil, bundle: nil)
        explosion_action_view_controller.bounds_for_view = @bounds
        explosion_action_view_controller.modalPresentationStyle = UIModalPresentationFullScreen
        explosion_action_view_controller.selected = @selected_toy
        explosion_action_view_controller.scene_creator_view_controller = @scene_creator_view_controller
        presentViewController(explosion_action_view_controller, animated: false, completion: nil)

      when :apply_torque
        torque_action_view_controller = RotationActionViewController.alloc.initWithNibName(nil, bundle: nil)
        torque_action_view_controller.bounds_for_view = @bounds
        torque_action_view_controller.modalPresentationStyle = UIModalPresentationFullScreen
        torque_action_view_controller.selected = @selected_toy
        torque_action_view_controller.scene_creator_view_controller = @scene_creator_view_controller
        presentViewController(torque_action_view_controller, animated: false, completion: nil)

      when :create_new_toy
        content = CollectionViewPopoverViewController.alloc.initWithNibName(nil, bundle: nil)
        content.delegate = self
        content.mode = :toys
        content.state = @state
        content.setTitle(Language::CHOOSE_CREATE_TOY)
        show_popover(content)

      when :move_towards
        content = CollectionViewPopoverViewController.alloc.initWithNibName(nil, bundle: nil)
        content.delegate = self
        content.mode = :move_towards
        content.state = @state
        content.setTitle(Language::MOVE_TOWARDS)
        show_popover(content)

      when :move_away
        content = CollectionViewPopoverViewController.alloc.initWithNibName(nil, bundle: nil)
        content.delegate = self
        content.mode = :move_away
        content.state = @state
        content.setTitle(Language::MOVE_AWAY)
        show_popover(content)

      when :delete_effect
        action_type, action_param = get_action
        effect_type = :delete_effect
        effect_param = DELETE_FADE_TIME
        create_action_effect(@selected_toy, action_type, action_param, effect_type, effect_param)
        action_created
      when :score_adder
        content = ScoreAdderActionViewController.alloc.initWithNibName(nil, bundle: nil)
        content.setTitle(Language::SCORE_ADDER_COMMAND)
        content.delegate = self
        show_popover(content)
      when :play_sound
        content = SoundSelectPopoverViewController.alloc.initWithNibName(nil, bundle: nil)
        content.delegate = self
        show_popover(content)
      when :text_bubble
        content = StringInputPopOverViewController.alloc.initWithNibName(nil, bundle: nil)
        content.delegate = self
        content.setTitle("What does the Fox say?")
        show_popover(content)
      when :scene_shift
        scene_box_view_controller = SceneBoxViewController.alloc.initWithNibName(nil, bundle: nil)
        scene_box_view_controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical
        scene_box_view_controller.modalPresentationStyle = UIModalPresentationPageSheet
        scene_box_view_controller.delegate = self
        scene_box_view_controller.state = @state
        presentViewController(scene_box_view_controller, animated: true, completion: nil)
      when :send_message
        content = MessagePopOverViewController.alloc.initWithNibName(nil, bundle: nil)
        content.delegate = self
        content.setTitle("What message do you want to send?")
        show_popover(content)
      else

    end
  end

  def submit_score_adder(number, type)
    close_popover
    action_type, action_param = get_action
    effect_type = :score_adder
    effect_param = [number.to_i, type]
    create_action_effect(@selected_toy, action_type, action_param, effect_type, effect_param)
    action_created
  end

  def set_sound(sound_name)
    close_popover
    action_type, action_param = get_action
    effect_type = :play_sound
    effect_param = sound_name
    create_action_effect(@selected_toy, action_type, action_param, effect_type, effect_param)
    action_created
  end

  def submit_text(text)
    action_type, action_param = get_action
    effect_type = :text_bubble
    effect_param = text
    create_action_effect(@selected_toy, action_type, action_param, effect_type, effect_param)
    action_created
  end

  def submit_message(text)
    action_type, action_param = get_action
    effect_type = :send_message
    effect_param = text
    create_action_effect(@selected_toy, action_type, action_param, effect_type, effect_param)
    action_created
  end

  def move_towards_action(other_toys)
    close_popover
    action_type, action_param = get_action
    effect_type = :move_towards
    effect_param = other_toys.identifier
    create_action_effect(@selected_toy, action_type, action_param, effect_type, effect_param)
    action_created
  end

  def move_away_action(other_toys)
    close_popover
    action_type, action_param = get_action
    effect_type = :move_away
    effect_param = other_toys.identifier
    create_action_effect(@selected_toy, action_type, action_param, effect_type, effect_param)
    action_created
  end

  # choose toy for applying effect
  def chose_toy(toy_index)
    #find mode of latest collection popover that was not toy (should be 2nd last)
    if @popoverStack[-2].is_a?(CollectionViewPopoverViewController)
      case @popoverStack[-2].mode
        when :actions
          #add toy param to action (collision)
          @colliding_toy = @state.toys[toy_index]
          close_popover
          show_effects_popover
        when :effects
          if @popoverStack[-1].mode == :move_towards
            close_popover
            # Minh: now here add move toward or sthing, message with other toys
            move_towards_action(@state.toys[toy_index])
          elsif @popoverStack[-1].mode == :move_away
            close_popover
            # Minh: now here add move toward or sthing, message with other toys
            move_away_action(@state.toys[toy_index])
          else
            close_popover
            drag_action_view_controller = CreateActionViewController.alloc.initWithNibName(nil, bundle: nil)
            drag_action_view_controller.bounds_for_view = @bounds
            drag_action_view_controller.modalPresentationStyle = UIModalPresentationFullScreen
            drag_action_view_controller.selected = @selected_toy
            drag_action_view_controller.new_toy = ToyInScene.new(@state.toys[toy_index])
            drag_action_view_controller.scene_creator_view_controller = @scene_creator_view_controller
            presentViewController(drag_action_view_controller, animated: false, completion: nil)
          end
        else
          puts "others"
      end
    end
  end

  def getSelectedToy
    @selected_toy
  end

  def show_popover(content)
    #if already showing, change rather than create new?
    @popover = UIPopoverController.alloc.initWithContentViewController(content)
    @popover.passthroughViews = [@main_view, @scene_creator_view_controller.view] #not working? should allow dragging while popover open
    @popover.delegate = self
    viewy = self.view
    #if @selected_toy == nil
    #  frame = CGRectMake(0,0,95,95)
    #else
    #  frame = CGRectMake(@selected_toy.position.x,@selected_toy.position.y-@selected_toy.image.size.height/2,*@selected_toy.image.size)
    #end
    x = @bounds.size.width/2 - 350/2
    frame = CGRectMake(0,0, x, 200)

    @popover.presentPopoverFromRect(frame , inView: viewy, permittedArrowDirections: UIPopoverArrowDirectionLeft | UIPopoverArrowDirectionRight, animated:true)
    @popoverStack << content
  end

  def close_popover
    if not @popover.nil?
      @popover_type = nil
      @popover.dismissPopoverAnimated(true)
    end
    disableButtons
    hide_sides
  end

  def change_popover(content)
    @popover.contentViewController = content
    @popoverStack << content
  end

  def action_created
    #remove popovers from stack until get to action viewer (don't want to allow going back and editing action)
    while not @popoverStack[-1].is_a?(ActionListPopoverViewController)
      @popoverStack.pop
    end
    @popoverStack[-1].state = @state
    reopen_action_flow
  end

  # Deletes the selected stroke or toy.
  def remove_selected(selected)
    case selected
      when Stroke
        @main_view.remove_stroke(selected)
      when ToyInScene
        @main_view.remove_toy(selected)
    end
    close_popover
    moveToSceneBar
  end

  # Deletes the selected stroke or toy.
  def edit_selected(selected)
    case selected
      when ToyInScene
        #p "toy in scene"
        #@main_view.remove_toy(selected)
        #p "toy edit = #{selected}"
        close_popover
        moveToToyBar(selected.template)
    end
  end
end