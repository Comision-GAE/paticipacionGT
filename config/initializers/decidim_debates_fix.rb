Rails.application.config.to_prepare do
module LocatorPatch
    def path(options = {})
    # Registros huérfanos (componente eliminado): evita error 500
    return "#" if resource.respond_to?(:component) && resource.component.nil?

    # Ruta manual para reuniones (parche anterior, se conserva)
    if resource.class.name == "Decidim::Meetings::Meeting" && resource.try(:participatory_space)
        sp = resource.participatory_space.class.name.include?("Assembly") ? "assemblies" : "processes"
        return "/#{sp}/#{resource.participatory_space.slug}/f/#{resource.component.id}/meetings/#{resource.id}"
    end

    super
    rescue StandardError => e
    Rails.logger.warn("[LocatorPatch] #{resource.class}##{resource.try(:id)}: #{e.class}: #{e.message}")
    "#"
    end
end

unless Decidim::ResourceLocatorPresenter < LocatorPatch
    Decidim::ResourceLocatorPresenter.prepend(LocatorPatch)
end
end






# Rails.application.config.to_prepare do
# Decidim::ResourceLocatorPresenter.class_eval do
#     # Agregamos (*args) para que acepte el locale o cualquier opción que Rails le mande
#     def path(*args)
#     # 1. Protección contra registros huérfanos/zombies
#     if resource.respond_to?(:component) && resource.component.nil?
#         return "#"
#     end

#     # 2. Intento de generar la ruta original
#     begin
#         route_proxy.public_send(member_route, mounted_params)
#     rescue
#         "#"
#     end
#     end
# end
# end

