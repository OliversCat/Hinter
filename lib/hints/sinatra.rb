require 'sinatra/base'
require 'json'
require 'rush/engine'
require 'rush/config'

module Sinatra
    module Rush
        def rush_go(option)
            conf = Configuration.new(option) do |c|
                c.set? :out, STDOUT
                c.set? :err, STDERR
            end

            Out = conf[:out]
            Err = conf[:err]

            known_verb = ["get", "post", "put", "delete",  "patch",  "options",  "link",  "unlink",
                         "rget","rpost","rput","rdelete", "rpatch", "roptions", "rlink", "runlink",
                         "filter"].freeze

            Out << "InitRushFramework..."

            Engine.new(conf) do |e|
                conf[:controller].each do |c|
                    Out << "->Loading Controller: #{c[:klass]}"
                    e.compile(c[:file]) do |verb, action, endpoint, option, param|
                        # Example:
                        # file: <rush_home>/controller/user_controller.rb  (<file>)
                        #
                        # class UserController < RushController      (<klass>)
                        #   [:get] => default endpoint: /user/login  (/<name>/<action>)
                        #   def login
                        #   end
                        # end
                        #   
                        endpoint << "\"#{c[:name]}/#{action == 'index' ? '' : action}\"" if endpoint == ""
                        endpoint << ", #{option}" unless option.empty?
                        endpoint.sub!("#","")

                        Out << "          ┗-> Action: #{verb} #{endpoint} (#{param.join(',')})"

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
                                    if enable_raze_view then
                                        view("#{controller}/#{action}", @instance.localBinding) 
                                    else
                                        action_result
                                    end
                                end
                                RUBY2
                            end

                            eval(eval_str1<<eval_str2, nil, __FILE__, __LINE__ + 77)

                        when "filter"
                            raise ArgumentError, "Bad Filter: #{action} used." unless action.start_with?('_') or action.end_with?('_') 
                            filter = action.start_with?('_') ? 'before' : 'after'
                            endpoint = "\"#{controller}/#{action.sub('_','')}\""
                            endpoint << ", #{option}" if option != ''

                            if ['__rootscope','rootscope__'].include?(action) then 
                                eval_str = "#{filter} "
                            else
                                endpoint = "\"#{controller}/*\"" if ['__scope','scope__'].include?(action)
                                eval_str = "#{filter} #{endpoint}"
                            end

                            eval_str << " do
                                            puts '->Forward to #{klass}.#{action}'
                                            @instance = ::#{klass}.new
                                            @instance.forward(self, '#{action}', #{param})
                                        end"

                            eval(eval_str, nil, __FILE__, __LINE__ + 103)
                        end
                    end
                end
            end
            
        rescue Exception => e
            Err "┗>#{e.inspect}"
            Err " ┗>#{e.backtrace.join("\n   ")}"
            Err "Failed to init RushFramework, exit 1."
            exit(1)
        end
    end

    register Rush
end