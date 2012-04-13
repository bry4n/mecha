module Mecha
  class AccessDeniedError < Exception; end
  module Sandbox

    def self.included(base)
      base.extend Mecha::Sandbox::ClassMethods
    end

    module ClassMethods

      def attr_forbidden(method_name)
        apply_rule :deny, method_name
      end 

      def rules
        @rules ||= {deny: [], allow: []}
      end

      def apply_rule(type, method_name)
        if type == :deny
          rules[:allow].delete(method_name) if methods_include?(:allow, method_name)
        else
          rules[:deny].delete(method_name) if methods_include?(:deny, method_name)
        end
        rules[type] << method_name unless methods_include?(type, method_name)
      end

      def methods_include?(type, method_name)
        rules[type].include?(method_name)
      end

    end

    def sandbox_activate!
      initialize_allowed_methods!
      initialize_disabled_methods!
    end

    private 

    def rules
      self.class.rules
    end

    def sandbox_denied?
      rules[:deny].select do |method_name|
        caller_methods.include?(method_name.to_s)
      end.one?
    end

    def initialize_allowed_methods!
      rules[:allow] = (methods + protected_methods + private_methods + public_methods) - rules[:deny]
    end

    def initialize_disabled_methods!
      rules[:deny].each do |method_name|
        name = method_arity(method_name)
        instance_eval(<<-METHOD, $0)
          alias :__#{name} :#{name}
          def #{name}
            raise Mecha::AccessDeniedError, "Access Denied: '#{method_name}' is forbidden!" if sandbox_denied?
            __#{method_name}
          end
        METHOD
      end
    end

    def method_arity(name)
      method_name = case self.method(name).arity
                    when 0 then name
                    when 1 then "#{name}(a)"
                    when 2 then "#{name}(a, b)"
                    when 3 then "#{name}(a, b, c)"
                    when 4 then "#{name}(a, b, c, d)"
                    when 5 then "#{name}(a, b, c, d, e)"
                    when -1 then "#{name}(*a)"
                    else name
                    end
    end

    def caller_methods
      callers.map(&:last)
    end

    def callers
      caller.map do |line|
        if line =~ /^(.+?):(\d+)(?::in `(.*)')?/
          file = Regexp.last_match[1]
          line = Regexp.last_match[2].to_i
          name = Regexp.last_match[3]
          [file, line, name]
        end
      end.compact
    end
  end
end

