# -*- coding: utf-8 -*-
$:.unshift("/Library/RubyMotion/lib")
require 'motion/project/template/ios'
#require 'bubble-wrap/core'

#begin
#  require 'bundler'
#  Bundler.require
#rescue LoadError
#end

Motion::Project::App.setup do |app|
  # Use `rake config' to see complete project settings.
  app.name = 'Fizz'
  #app.files_dependencies 'app/app_delegate.rb' => 'app/controllers/creator_view_controller.rb'
  app.provisioning_profile = '/Users/robert/Library/MobileDevice/Provisioning Profiles/76C88BEF-43F5-4000-93B3-F05DCA685B0C.mobileprovision'
  app.codesign_certificate = 'iPhone Developer: Robert Sheehan (VZ2335Q656)'

  app.device_family = [:ipad]
  app.interface_orientations = [:landscape_left, :landscape_right]
  # need both the following lines to turn status bar off
  app.info_plist['UIViewControllerBasedStatusBarAppearance'] = false
  app.info_plist['UIStatusBarHidden'] = true
  #app.frameworks += ['CoreData']
  app.frameworks += ['SpriteKit']
end
