require 'sinatra/base'
require 'json'
require 'hints/engine'
require 'hints/config'

module Sinatra
  module Hints
    def hints_setup(option={})
      conf = Configuration.new(option) do |c|
          c.set? :out, STDOUT
          c.set? :err, STDERR
          c.set? :working_dir, "/handler/"
          c.set? :hints_home, settings.root + c.get(:working_dir)
          c.set  :known_verb, ["get", "post", "put", "delete",  
                               "patch",  "options",  "link",  "unlink",
                               "rget","rpost","rput","rdelete", 
                               "rpatch", "roptions", "rlink", "runlink",
                               "filter"].freeze
      end

      out = conf[:out]
      err = conf[:err]

      out << "Init Hints..."

      Engine.new(conf) do |e|
          conf[:controller].each do |c|
              out << "->Loading Controller: #{c[:klass]}"
              e.compile(c[:file]) do |verb, action, endpoint, option, param|
                  # Example:
                  # => file: <hints_home>/controller/user.rb  #<file>
                  # => class User                             #<klass>
                  #     include Hint
                  #
                  #     [:get <verb>] => default endpoint: /user/login  #<endpoint> = /<name>/<action>
                  #     def login  #<action>
                  #     end
                  #    end
                  #
                  # Name Convention:
                  # => file: <hints_home>/controller/user_login.rb  #<file>
                  # => class UserLogin                              #<klass>
                  #     include Hint
                  #     
                  #     [:get <verb>] => default endpoint: /user/login/authetnicate  #<endpoint> = /<name>/<action>
                  #     def authetnicate(uid, pass)   #<action>
                  #     end
                  #    end
                  #
                  #   <file>           <klass>          <name>
                  #   oliver_cat.rb => OliverCat => /oliver/cat/<action>  #<endpoint>
                  #   
                  endpoint << "\"#{c[:name]}/#{action == 'index' ? '' : action}\"" if endpoint == ""
                  endpoint << ", #{option}" unless option.empty?
                  endpoint.sub!("#","")

                  out << "          ┗-> Action: #{verb} #{endpoint} (#{param.join(',')})"

                  case verb
                  when "get", "post", "put", "delete",  "patch",  "options",  "link",  "unlink",
                       "rget","rpost","rput","rdelete", "rpatch", "roptions", "rlink", "runlink"

                      eval_str1 = <<-RUBY1
                          #{verb.sub(/^r/,'')} #{endpoint} do
                              puts '->Forward to #{klass}.#{action}'  
                              if @instance == nil
                                  @instance = ::#{klass}.new
                              else
                                  if @instance.class != #{klass}
                                      out << "->Warn: @instance.class = #{@instance.class} => #{klass}"
                                      @instance = ::#{klass}.new
                                  end
                              end

                          RUBY1

                      if verb =~ /^r/
                          eval_str2 = <<-RUBY2
                              headers['Content-Type'] = 'json'
                              if (body_content = request.body.read).length > 0 then
                                  JSON.parse(body_content).each_pair{ |k,v|
                                      params[k] = v
                                  }
                              end

                              action_result = @instance.forward(self, "#{action}", #{param})
                              if headers['Content-Type'] == 'json' then
                                  action_result.to_json 
                              else
                                  action_result
                              end
                          end
                          RUBY2
                      else
                          eval_str2 = <<-RUBY2
                              action_result = @instance.forward(self, "#{action}", #{param})
                          end
                          RUBY2
                      end

                      eval(eval_str1<<eval_str2)

                  when "filter"
                      raise ArgumentError, "Bad Filter: #{action} used. Filter should start and end with '_'" unless action.start_with?('_') or action.end_with?('_') 
                      filter = action.start_with?('_') ? 'before' : 'after'
                      endpoint = "\"#{c[:name]}/#{action.sub('_','')}\""
                      endpoint << ", #{option}" if option != ''

                      if ['__rootscope','rootscope__'].include?(action) then 
                          eval_str = "#{filter} "
                      else
                          endpoint = "\"#{c[:name]}/*\"" if ['__scope','scope__'].include?(action)
                          eval_str = "#{filter} #{endpoint}"
                      end

                      eval_str << " do
                                      puts '->Forward to #{klass}.#{action}'
                                      @instance = ::#{klass}.new
                                      @instance.forward(self, '#{action}', #{param})
                                  end"

                      eval(eval_str)
                  end
              end
          end
      end
        
    rescue Exception => e
        err "┗>#{e.inspect}"
        err " ┗>#{e.backtrace.join("\n   ")}"
        err "Failed to init Hints, exit 1."
        exit(1)
    end
  end

  register Hints
end