# frozen_string_literal: true

require "rails_helper"
describe "Home content block menu" do
  let(:organization) { create(:organization) }
  let!(:menu_content_block) { create(:content_block, organization:, manifest_name: :global_menu, scope_name: :homepage) }
  let(:current_locale) { "es" }
  before do
    switch_to_host(organization.host)
    visit decidim.root_path(locale: current_locale)
    
  end

  context "when the home content block menu is present" do
    it "displays the modified additional menus" do

      within "#home__menu" do
        expect(page).to have_content("Sobre la plataforma")
        expect(page).to have_content("Inicio")
      end
    end
  end
end