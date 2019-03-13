module PuppetX
  module SensuGo
    module Type

      def add_autorequires(namespace=true, require_configure=true)
        autorequire(:package) do
          ['sensu-go-cli']
        end

        autorequire(:service) do
          ['sensu-backend']
        end

        if require_configure
          autorequire(:sensugo_configure) do
            ['puppet']
          end
        end

        autorequire(:sensugo_api_validator) do
          [ 'sensu' ]
        end

        if namespace
          autorequire(:sensugo_namespace) do
            [ self[:namespace] ]
          end
        end
      end
    end
  end
end
