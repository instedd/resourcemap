module CanCan
  class ControllerResource

    def resource_instance
      if load_instance?
        if use_decent_exposure?
          @controller.send(instance_name) 
        else
          @controller.instance_variable_get("@#{instance_name}")
        end
      end

    end

    def use_decent_exposure?
      @options[:decent_exposure] && @controller.respond_to?(instance_name)
    end

  end
end