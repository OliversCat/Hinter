module Sinatra
    module Rush
      class Engine
        def initialize(options = {}, &blk)
            options ||= {}
            @options = options
            @options[:controller] = []
            blk.call self
        end

        def compile(src_data)
          scope_on = false
          scope = {:verb => '', :option => '', :endpoint => '', :action => '', :paramset => []} 

          r_verb    = %r{#\[:(?<verb>[a-z]+)\]}
          r_option  = %r{#\[:option(?<option>.*)\]}
          r_endpoint  = %r{#\[:endpoint(?<endpoint>.*)\]}
          r_def     = %r{def\s+(?<def>[a-z!?_\s]+)(?<paramset>[(),a-z_\s]+)}

          src_data.each do |line|
            if scope_on
              if check = line.match(r_option)
                scope[:option] = check[:option].strip
              elsif check = line.match(r_endpoint)
                scope[:endpoint]= check[:endpoint].strip
              elsif check = line.match(r_def)
                scope[:action] = check[:def].strip
                if check[:paramset]
                  scope[:paramset] = check[:paramset].sub("(","")
                                        .sub(")","")
                                        .strip.split(",")
                                        .map(&:strip)
                end
                yield(scope[:verb], scope[:action], scope[:endpoint], scope[:option], scope[:paramset])
                scope_on = false
                scope.each_value(&:clear)
              end 
            else
              if check = line.match(r_verb)
                if KnownVerb.include?(check[:verb])
                  scope_on = true
                  scope[:verb] = check[:verb].strip
                end
              end
            end
          end
        end

        private
        def load
            if rush_home = @options[:rush_home] then
                Dir.entries(rush_home).select{|f| f.end_with? ".rb"}.each do |f|
                    klass = f.sub(".rb","").split("_").map(&:capitalize).join.sub("#","")
                    name = "/#{f.sub(".rb","").split('_')[0..-2].join.downcase}".sub("#","").sub("/home","")
                    @options[:controller] << {name:name, klass:klass, file:"#{rush_home}/f"}
                    require f
                end
            else
                raise "Rush Controller Dir was not set."
            end
        end
      end
    end
end
