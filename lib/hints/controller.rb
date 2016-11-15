module Hint
  def forward(refer_obj, fun, fun_paramset = [])
    @ref_obj = refer_obj

    res = catch(:hint_halt){
      if fun_paramset.size > 0
        missing_params = fun_paramset.select{|x| params.has_key?(x) == false}
        if missing_params.length > 0 then
          hint_halt(Result.Fail("Missing Parameters: #{missing_params.join(',')}"))
        else
          self.method(fun.to_sym).call(*fun_paramset.map!{|x| params[x]})
        end
      else
        self.method(fun.to_sym).call
      end
    }
    return res if res!= nil
  end

  def localBinding
    return binding()
  end

  def method_missing(fun, *param, &block)
    if @ref_obj.respond_to? fun then

      self.class.send(:define_method, fun){|*param|
        @ref_obj.send(fun, *param, &block)
      }
      self.send(fun, *param, &block)
    else
      raise NameError, "undefined local variable or method `#{fun}' for #{self.to_s}"
    end
  end

  def hint_halt(msg)
    throw :hint_halt, msg
  end

  class Result
    def self.Success(msg=nil)
      rtn = {}
      rtn[:result] = true
      rtn[:msg] = msg if msg
      rtn[:data] = yield if block_given?
      rtn
    end

    def self.Fail(msg=nil)
      rtn = {}
      rtn[:result] = false
      rtn[:msg] = msg if msg
      rtn[:data] = yield if block_given?
      rtn
    end
  end


end
