class Routes
  def route(path, context)
    if path.starts_with?("/api/collections/")
      controller = CollectionsController.new
      controller.context = context
      controller.show(path.split("/").last.to_i)
      return
    end

    raise "unable to process #{path}"
  end
end
