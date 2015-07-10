class Routes
  def route(path, params)
    if path.starts_with?("/api/collections/")
      controller = CollectionsController.new
      controller.params = params
      controller.show(path.split("/").last.to_i)
      return
    end

    raise "unable to process #{path}"
  end
end
