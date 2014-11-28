
# Lets call this an abstract class!
class CenterToyViewController < UIViewController
  attr_writer :selected
  attr_reader :toy_origin
  attr_writer :scene_creator_view_controller

  def viewDidAppear(animated)
    @toy_origin = @selected.position
    @toy_origin_angle = @selected.angle

    @duration = 0.8
    @delay = 0.1
    lowerAlpha = 0.05
    @selected.move_to(@main_view.center, 0, @duration, @delay)

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
    @popover.dismissPopoverAnimated(true)
    #@selected.angle = @toy_origin_angle
    @selected.move_to(@toy_origin + CGPointMake(100, 0), @toy_origin_angle, @duration, @delay)
    @timer = NSTimer.scheduledTimerWithTimeInterval(@delay, target: self, selector: "animate:", userInfo: [@delta_alpha*-1, 0], repeats: true)

  end

  def animate(timer)
    if timer.userInfo[1] < @how_many_times
      @scene_creator_view_controller.main_view.alpha_view -= timer.userInfo[0]
    else
      timer.invalidate
      return
    end
    timer.userInfo[1]+=1
    @scene_creator_view_controller.refresh
  end

  def action_flow_back
    @main_view.delegate.back_from_modal_view = true
    @main_view.delegate.close_modal_view
    @main_view.delegate.reopen_action_flow
    @main_view.delegate.back_from_modal_view = false
  end


  # Add force when random parameters are selected
  def addForce(force)
    if @popover_title == Language::FORCE_TITLE
      @main_view.delegate.force = force
    elsif @popover_title == Language::ROTATION_TITLE
      @main_view.delegate.rotation = Constants::RANDOM_HASH_KEY
    elsif @popover_title == Language::EXPLOSION_TITLE
      @main_view.delegate.explosion = Constants::RANDOM_HASH_KEY
    end
    @main_view.delegate.close_modal_view
  end
end