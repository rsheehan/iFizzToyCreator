class AppDelegate
  def application(application, didFinishLaunchingWithOptions: launchOptions)

    application.applicationSupportsShakeToEdit = true
    application.setStatusBarHidden(true, withAnimation:UIStatusBarAnimationSlide)
    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    @uiMainTab = UITabBarControllerLandscape.alloc.init
    @window.rootViewController = @uiMainTab
    @window.makeKeyAndVisible # do this early otherwise some of the dimensions are wrong



  #   bundleRoot = NSBundle.mainBundle.bundlePath

  #   the_image = UIImage.imageNamed("bground.jpg")


      
  #     paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true)
  #     documents_path = paths.objectAtIndex(0) # Get the docs directory
  #     timeStamp = Time.now.to_s.gsub! ' ', '_'
  #     file_name = bundleRoot + "/" + timeStamp + "_bground.png"
      
  #     puts "Writing image to #{file_name}"
  #     writeData = UIImagePNGRepresentation(the_image)
  #     writeData.writeToFile(file_name, atomically: true)

  #     dirContents = NSFileManager.defaultManager.directoryContentsAtPath(bundleRoot)
  # dirContents.each do |fileName|
  #   if fileName.hasSuffix("bground.png") || fileName.hasSuffix("bground.jpg")
  #     p fileName
  #   end
  # end
  #     p "finish"
  #File.remove()

    true
  end
end

