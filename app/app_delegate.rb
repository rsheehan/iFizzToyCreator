class AppDelegate
  def application(application, didFinishLaunchingWithOptions: launchOptions)
    application.applicationSupportsShakeToEdit = true
    application.setStatusBarHidden(true, withAnimation:UIStatusBarAnimationSlide)
    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    @uiMainTab = UITabBarControllerLandscape.alloc.init
    @window.rootViewController = @uiMainTab
    @window.makeKeyAndVisible # do this early otherwise some of the dimensions are wrong
    @window.backgroundColor = Constants::GRAY
    # Setting of some global properties
    UIButton.appearance.setTintColor(Constants::BUTTON_TINT_COLOR)
    UIButton.appearance.setFont(UIFont.systemFontOfSize(Constants::GENERAL_BUTTON_FONT_SIZE))
    true
  end
end

