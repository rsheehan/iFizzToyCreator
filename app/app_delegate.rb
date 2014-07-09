class AppDelegate

  TAB_HEIGHT = 56 # this was the returned tab bar height

  def application(application, didFinishLaunchingWithOptions: launchOptions)
    application.applicationSupportsShakeToEdit = true

    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    @window.makeKeyAndVisible # do this early otherwise some of the dimensions are wrong

    controllers = []
    icons = []

    controllers << toy_creator_view_controller = ToyCreatorViewController.alloc.initWithNibName(nil, bundle: nil)
    icons << icon_and_title(toy_creator_view_controller, Language::MAKE_TOYS, 'toy_for_tab_bar')

    play_view_controller = PlayViewController.alloc.initWithNibName(nil, bundle: nil)

    controllers << scene_creator_view_controller = SceneCreatorViewController.alloc.initWithNibName(nil, bundle: nil)
    icons << icon_and_title(scene_creator_view_controller, Language::MAKE_SCENES, 'scene_for_tab_bar')
    scene_creator_view_controller.play_view_controller = play_view_controller

    controllers << action_creator_view_controller = ActionAdderViewController.alloc.initWithNibName(nil, bundle: nil)
    icons << icon_and_title(action_creator_view_controller, Language::ADD_ACTIONS, 'action_for_tab_bar')
    action_creator_view_controller.scene_creator_view_controller = scene_creator_view_controller
    action_creator_view_controller.play_view_controller = play_view_controller

    controllers << play_view_controller
    icons << icon_and_title(play_view_controller, Language::PLAY, 'play_for_tab_bar')

    origin = @window.bounds.origin
    size = @window.bounds.size

    #tab_height = tab_bar.bounds.size.height # doesn't work
    view_bounds = CGRectMake(origin.x, origin.y, size.height, size.width - TAB_HEIGHT)

    controllers.each { |controller| controller.bounds_for_view = view_bounds }
    # Now set up my models
    @state = State.new
    controllers.each { |controller| controller.state = @state }
    #toy_creator_view_controller.state = state

    tab_bar_controller = UITabBarController.alloc.init
    tab_bar_controller.setViewControllers(controllers, animated: true)

    # The following line is to remove a warning message about two-stage animation in iOS 7.
    # If the tab_bar_controller selected view controller is set to toy_creator_view_controller
    # first up then the buttons on the rhs are not active because it acts as if it is in portrait mode.
    tab_bar_controller.selectedViewController = scene_creator_view_controller
    @window.rootViewController = tab_bar_controller
    tab_bar_controller.selectedViewController = toy_creator_view_controller

    tab_bar = tab_bar_controller.tabBar
    icons.each_with_index { |icon, i| tab_bar.items[i].image = icon }

    true
  end

  def applicationWillResignActive(application)
    @state.save
    while(@state.is_saving)

    end

  end

  # returns with the icon image
  def icon_and_title(controller, title, icon_name)
    controller.title = title
    UIImage.imageNamed(icon_name)
  end

end
