
# Lets call this an abstract class!
class CenterToyViewController < UIViewController
  attr_writer :selected
  attr_reader :toy_origin
  attr_writer :scene_creator_view_controller

  def viewDidAppear(animated)
    #Refresh UIView for moved toy
    @toy_origin = @selected.position
    toy_center = CGPointMake(100, 0)
    center = @main_view.center
    center_diff = center - toy_center
    #@selected.change_position(true_center)
    @diff = center_diff - @toy_origin
    duration = 0.5
    @delay = 0.01
    lowerAlpha = 0.3
    #transform = CGAffineTransformMakeTranslation(diff.x, diff.y)
    #puts "Diff , X: " + transform.tx.to_s + ", Y: " + transform.ty.to_s
    #@scene_creat@=or_view_controller.main_view.shift_view_by(@diff)
    @how_many_times = duration/@delay
    @diff_constant_time = @diff / @how_many_times
    @delta_alpha = (1-lowerAlpha) / @how_many_times
    @count = 0
    @timer = NSTimer.scheduledTimerWithTimeInterval(@delay, target: self, selector: "animate:", userInfo: [@diff_constant_time, @delta_alpha], repeats: true)
    @scene_creator_view_controller.refresh
  end

  def viewDidDisappear(animated)
    #@scene_creator_view_controller.main_view.shift_view_by(@diff*-1)
    #@selected.change_position(@toy_origin)
    @count = 0
    @timer = NSTimer.scheduledTimerWithTimeInterval(@delay, target: self, selector: "animate:", userInfo: [@diff_constant_time*-1, @delta_alpha*-1], repeats: true)
  end

  def animate(timer)
    if @count < @how_many_times
      @selected.change_position(@selected.position + timer.userInfo[0])
      @scene_creator_view_controller.main_view.alpha_view -= timer.userInfo[1]
    else
      @timer.invalidate
      @timer = nil
      return
    end
    @count+=1
    @scene_creator_view_controller.refresh
  end

end