module VueCli
  module Rails
    module Helper
      def vue_entry(entry)
        assets = VueCli::Rails::Configuration.instance.entry_assets(entry)
        raise(ArgumentError, "Vue entry (#{entry}) not found!") if assets.blank?

        tags = ''.dup
        (assets['css'] || []).each do |css|
          tags << %{<link href="#{css}" rel="stylesheet">}
        end
        (assets['js'] || []).each do |js|
          tags << %{<script src="#{js}"></script>}
        end
        tags.html_safe
      end
    end
  end
end
