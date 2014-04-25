class ShowActionViewController< UIViewController

    attr_writer :delegate, :scene_creator_view_controller

    def loadView # preferable to viewDidLoad because not using xib
      # Do not call super.
      action_over_view = UIView.alloc.init
      self.view = action_over_view
      @main_view = @scene_creator_view_controller.main_view
      @main_view.mode = :show_actions
      @main_view.show_action_controller = self
      view.addSubview(@main_view)
      @main_view.change_label_text_to(Language::VIEW_ACTIONS)

      command_label = UILabel.alloc.initWithFrame([[0, @bounds.size.height], [@bounds.size.width, 768 - @bounds.size.height]])
      command_label.backgroundColor = Constants::GOLD
      command_label.text = Language::SHOW_ACTIONS
      command_label.textAlignment = NSTextAlignmentCenter
      view.addSubview(command_label)

      #add done button to where show actions button was
      button = UIButton.buttonWithType(UIButtonTypeCustom)
      button.setImage(UIImage.imageNamed(:done), forState: UIControlStateNormal)
      button.sizeToFit
      button.frame = [[95+10,10], button.frame.size]
      button.addTarget(self, action: :done, forControlEvents: UIControlEventTouchUpInside)
      button.enabled = true
      view.addSubview(button)
      button
    end

    def bounds_for_view=(bounds)
      @bounds = bounds
    end

    def done
      #dismiss the controller
      @delegate.close_modal_view
    end

    def show_action_list(toy)
      #show modal with view of all associated actions and effects
      action_list_view_controller = ActionListViewController.alloc.initWithNibName(nil, bundle: nil)
      action_list_view_controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical
      action_list_view_controller.modalPresentationStyle = UIModalPresentationFormSheet
      action_list_view_controller.delegate = self
      action_list_view_controller.scene_creator_view_controller = @scene_creator_view_controller
      action_list_view_controller.selected = toy
      presentViewController(action_list_view_controller, animated: false, completion: nil)
    end

    def close_modal_view
      dismissModalViewControllerAnimated(false, completion: nil)
    end
end