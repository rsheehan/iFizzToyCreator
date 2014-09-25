class AppDelegate

  def application(application, didFinishLaunchingWithOptions: launchOptions)
    application.applicationSupportsShakeToEdit = true
    application.setStatusBarHidden(true, withAnimation:UIStatusBarAnimationSlide)
    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    @window.makeKeyAndVisible # do this early otherwise some of the dimensions are wrong

    @controllers = []
    icons = []

    # Make Toys view
    @controllers << toy_creator_view_controller = ToyCreatorViewController.alloc.initWithNibName(nil, bundle: nil)
    icons << icon_and_title(toy_creator_view_controller, Language::MAKE_TOYS, 'toy_for_tab_bar')

    # Make Scene view
    @controllers << scene_creator_view_controller = SceneCreatorViewController.alloc.initWithNibName(nil, bundle: nil)
    icons << icon_and_title(scene_creator_view_controller, Language::MAKE_SCENES, 'scene_for_tab_bar')

    # Add Actions View
    @controllers << action_creator_view_controller = ActionAdderViewController.alloc.initWithNibName(nil, bundle: nil)
    icons << icon_and_title(action_creator_view_controller, Language::ADD_ACTIONS, 'action_for_tab_bar')
    action_creator_view_controller.scene_creator_view_controller = scene_creator_view_controller

    # Play
    play_view_controller = PlayViewController.alloc.initWithNibName(nil, bundle: nil)
    @controllers << play_view_controller
    icons << icon_and_title(play_view_controller, Language::PLAY, 'play_for_tab_bar')

    origin = @window.bounds.origin
    size = @window.bounds.size

    @tab_bar_controller = UITabBarControllerLandscape.alloc.init
    tabBarHeight = @tab_bar_controller.tabBar.frame.size.height;

    # solve problem of rubymotion 2.33 vs previous version problems
    if size.height < size.width
      @view_bounds = CGRectMake(origin.x, origin.y, size.width, size.height - tabBarHeight)
    else
      @view_bounds = CGRectMake(origin.x, origin.y, size.height, size.width - tabBarHeight)
    end

    @controllers.each { |controller| controller.bounds_for_view = @view_bounds }
    # Now set up my models
    @state = State.new
    @controllers.each { |controller| controller.state = @state }
    #toy_creator_view_controller.state = state

    @tab_bar_controller.setViewControllers(@controllers, animated: true)

    # The following line is to remove a warning message about two-stage animation in iOS 7.
    # If the tab_bar_controller selected view controller is set to toy_creator_view_controller
    # first up then the buttons on the rhs are not active because it acts as if it is in portrait mode.
    @tab_bar_controller.selectedViewController = toy_creator_view_controller
    # CAN CHANGE TO scene_creator_view_controller
    @window.rootViewController = @tab_bar_controller

    tab_bar = @tab_bar_controller.tabBar
    icons.each_with_index { |icon, i| tab_bar.items[i].image = icon }

    true
  end

  # Saving after the app has closed
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

# Create here to allow landscape only but still be able to use image picker
class UITabBarControllerLandscape < UITabBarController
  def supportedInterfaceOrientations
    UIInterfaceOrientationMaskLandscape
  end
end