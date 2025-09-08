# frozen_string_literal: true

[:home_content_block_menu, :menu, :mobile_menu].each do |menu_name|
  Decidim.menu menu_name do |menu|
    menu.add_item :about, I18n.t("menu.about", scope: "decidim"), decidim.pages_path, position: 110
  end
end

Decidim.menu :home_content_block_menu do |menu|
  menu.add_item :home, I18n.t("menu.home", scope: "decidim"), decidim.root_path, position: 1
end