
# Lets call this an abstract class!
class CenterToyViewController < UIViewController
  attr_writer :selected
  attr_reader :toy_origin
  attr_writer :scene_creator_view_controller

  def viewDidAppear(animated)
    #Refresh UIView for moved toy
    @toy_origin = @selected.position
    # toy_center = CGPointMake(100, 0)
    # center = @main_view.center
    # center_diff = center - toy_center
    # #@selected.change_position(true_center)
    # @diff = center_diff - @toy_origin
    @duration = 0.8
    @delay = 0.1
    lowerAlpha = 0.05
    #transform = CGAffineTransformMakeTranslation(diff.x, diff.y)
    #puts "Diff , X: " + transform.tx.to_s + ", Y: " + transform.ty.to_s
    #@scene_creat@=or_view_controller.main_view.shift_view_by(@diff)
    @selected.move_to(@main_view.center, @duration, @delay)

    @how_many_times = @duration/@delay
    @delta_alpha = (1-lowerAlpha) / @how_many_times
    @timer = NSTimer.scheduledTimerWithTimeInterval(@delay, target: self, selector: "animate:", userInfo: [@delta_alpha, 0], repeats: true)

    content = TextPopoverViewController.alloc.initWithNibName(nil, bundle: nil)
    content.setTitle(@popover_title)
    content.setInstruction(@popover_instr)
    content.delegate = self
    @popover = UIPopoverController.alloc.initWithContentViewController(content)
    @popover.passthroughViews = [@main_view, @scene_creator_view_controller.view] #not working? should allow dragging while popover open
    @popover.delegate = self
    @popover.presentPopoverFromRect(CGRectMake(@main_view.center.x-5,@main_view.frame.origin.y,10,1) , inView: self.view, permittedArrowDirections: UIPopoverArrowDirectionUp, animated:true)

    @scene_creator_view_controller.refresh
  end

  def viewWillDisappear(animated)
    #@scene_creator_view_controller.main_view.shift_view_by(@diff*-1)
    #@selected.change_position(@toy_origin)
    @popover.dismissPopoverAnimated(true)
    @selected.move_to(@toy_origin, @duration, @delay)
    @timer = NSTimer.scheduledTimerWithTimeInterval(@delay, target: self, selector: "animate:", userInfo: [@delta_alpha*-1, 0], repeats: true)

  end

  def animate(timer)
    if timer.userInfo[1] < @how_many_times
      # @selected.change_position(@selected.position + timer.userInfo[0])
      @scene_creator_view_controller.main_view.alpha_view -= timer.userInfo[0]
    else
      timer.invalidate
      #@timer = nil
      return
    end
    timer.userInfo[1]+=1
    @scene_creator_view_controller.refresh
  end

  def action_flow_back
    #cancel adding effect
    @main_view.delegate.close_modal_view
    @main_view.delegate.reopen_action_flow
  end
end