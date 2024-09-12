module Bcome
  class Timer
    include ThreadSafeSingleton

    def elapsed
      time - @start_time 
    end

    def log(message)
      puts "[#{elapsed}] #{message}"
    end

    def start
      @start_time = time
    end

    def reset
      start
    end

    def time
      Time.now.to_i
    end
  end
end
