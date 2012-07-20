class Plugin
  include Singleton

  attr_accessor :routes_block

  class << self
    def inherited(plugin)
      super
      all << plugin.instance
    end

    def all
      @plugins ||= []
    end

    def find_by_names(*plugins)
      all.select { |plugin| plugins.include? plugin.name }
    end

    def routes &block
      instance.routes_block = block
    end

    def hooks(name)
      all.map do |plugin|
        plugin.hooks[name]
      end.flatten
    end

    # FIXME: currently only else block is being used
    def method_missing(method_name, *args, &block)
      if block_given?
        instance.hooks[method_name] << block
      else
        instance.hooks[method_name] << args.first
      end
    end
  end

  def name
    self.class.parent_name.underscore
  end

  def hooks
    @hooks ||= Hash.new { |h, k| h[k] = [] }
  end

  # FIXME: not being used
  def call_hook name, *args
    @hooks[name].each do |proc|
      proc.call *args
    end
  end
end
