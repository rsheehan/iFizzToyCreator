# The controller of the PlayScene.
class PlayViewController < UIViewController

  TOP = 10
  MIDDLE = 281
  BOTTOM = 552
  LEFT = 10
  #RIGHT = 939

  attr_writer :state

  def loadView # preferable to viewDidLoad because not using xib
    # Do not call super.
    play_over_view = UIView.alloc.init
    self.view = play_over_view

    location_of_play = [95, 0]
    @size_of_play = [@bounds.size.width - 190, @bounds.size.height]
    @play_view = SKView.alloc.initWithFrame([location_of_play, @size_of_play])
    @play_view.showsDrawCount = true
    @play_view.showsNodeCount = true
    @play_view.showsFPS = true
    view.addSubview(@play_view)
    @button_actions = {} # keys = buttons, values = list of actions for that button
    setup_sides
    @timers = []
  end

  def viewDidDisappear(animated)
    @timers.each do |timer|
      timer.invalidate
    end
  end

  def update_play_scene
    return unless @play_view # this is because of the orientation bug being worked around in app_delegate
    @play_scene = PlayScene.alloc.initWithSize(@play_view.frame.size)
    @play_scene.physicsWorld.contactDelegate = @play_scene

    # this is purely for development only uses the first scene

    # add the toys to the scene
    @play_scene.toys = @state.scenes[@state.currentscene].toys
    # add the edges to the scene
    @play_scene.edges = @state.scenes[@state.currentscene].edges
    # also go through the actions checking for button actions and enabling the buttons
    @button_actions.each_key do |button|
      @button_actions[button] = []
    end
    actions = @state.scenes[@state.currentscene].actions
    actions.each do |action|
      case action[:action_type]
        when :button
          button = enable_button(action[:action_param])
        #add_action_to_button
          @button_actions[button] << action
        when :timer
          puts("Action",action)
          @timers << NSTimer.scheduledTimerWithTimeInterval(action[:action_param][0]*60 + action[:action_param][1], target: self, selector: "perform_action:", userInfo: action, repeats: true)
        when :collision
          @play_scene.add_collision(action)
      end
    end

    # end of development code

    @play_view.presentScene(@play_scene)
  end

  def bounds_for_view=(bounds)
    @bounds = bounds
  end

  # The sides are left for user interactions to the running scenes
  def setup_sides
    left_panel = UIView.alloc.initWithFrame(CGRectMake(0, 0, 95, @bounds.size.height))
    left_panel.setBackgroundColor(UIColor.grayColor)
    @left_top_button = setup_button([LEFT, TOP], left_panel)
    @left_middle_button = setup_button([LEFT, MIDDLE], left_panel)
    @left_bottom_button = setup_button([LEFT, BOTTOM], left_panel,)
    view.addSubview(left_panel)
    right_panel = UIView.alloc.initWithFrame(CGRectMake(@bounds.size.width - 95, 0, 95, @bounds.size.height))
    right_panel.setBackgroundColor(UIColor.grayColor)
    @right_top_button = setup_button([LEFT, TOP], right_panel)
    @right_middle_button = setup_button([LEFT, MIDDLE], right_panel)
    @right_bottom_button = setup_button([LEFT, BOTTOM], right_panel)
    view.addSubview(right_panel)
  end

  def setup_button(position, panel)
    button = UIButton.buttonWithType(UIButtonTypeCustom)
    button.setImage(UIImage.imageNamed('side_button'), forState: UIControlStateNormal)
    button.setImage(UIImage.imageNamed('side_button_selected'), forState: UIControlStateHighlighted)
    button.sizeToFit
    button.frame = [position, button.frame.size]
    @button_actions[button] = []
    #button.tag = tag
    button.addTarget(self, action: 'button_action:', forControlEvents: UIControlEventTouchUpInside)
    button.enabled = false
    panel.addSubview(button)
    button
  end

  # Makes the button work
  # Also returns the button.
  def enable_button(name)
    button = case name
               when :left_top
                 @left_top_button
               when :left_middle
                 @left_middle_button
               when :left_bottom
                 @left_bottom_button
               when :right_top
                 @right_top_button
               when :right_middle
                 @right_middle_button
               when :right_bottom
                 @right_bottom_button
             end
    button.enabled = true
    button
  end

  def button_action(sender)
    # find the correct action and submit it for firing
    #puts "button: #{sender}"
    # pass the actions through to the scene for its update method to use
    @play_scene.add_actions_for_update(@button_actions[sender])
  end

  def perform_action(timer)
    puts(timer)
    puts(timer.userInfo)
    @play_scene.add_actions_for_update([timer.userInfo])
  end

end