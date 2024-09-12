module ThreadSafeSingleton
  def self.append_features(clazz)
    require 'thread'
      clazz.module_eval { 
        private_class_method :new
        @instance_mutex = Mutex.new
        def self.instance 
          @instance_mutex.synchronize {
          @instance = new unless @instance
          @instance
        }
      end
    }
  end
end
