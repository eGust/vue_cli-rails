module VueCli
  module Rails
    module Helper
      def vue_entry(name)
        @config ||= VueCli::Rails::Configuration.instance

        entry = (@config.manifest_data['entrypoints'] || {})[name]
        return raise(VueCli::Rails::Error, "Not found vue entry point: #{name}") if entry.blank?

        assets = []
        (entry['css'] || []).each do |css|
          assets << stylesheet_link_tag(css)
        end
        (entry['js'] || []).each do |js|
          assets << javascript_include_tag(js)
        end

        assets.join('').html_safe
      end
    end
  end
end
