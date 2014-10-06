class AppDelegate
  def application(application, didFinishLaunchingWithOptions: launchOptions)

    application.applicationSupportsShakeToEdit = true
    application.setStatusBarHidden(true, withAnimation:UIStatusBarAnimationSlide)
    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    @window.rootViewController = UITabBarControllerLandscape.alloc.init
    @window.makeKeyAndVisible # do this early otherwise some of the dimensions are wrong


    # bundleRoot = NSBundle.mainBundle.bundlePath
    # puts "bundle path: #{bundleRoot}"
    # dirContents = NSFileManager.defaultManager.directoryContentsAtPath(bundleRoot)
    # dirContents.each do |fileName|
    #   if fileName.hasSuffix(".wav") || fileName.hasSuffix(".mp3")
    #     puts "File name = #{fileName}"
    #   end
    # end

    #temp = Math.sqrt(20)
    #puts "#{temp}"


    true
  end
end

