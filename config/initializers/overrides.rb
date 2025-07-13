DecidimGuatemala::Application.config.to_prepare do
  Decidim::Proposals::ProposalGCell.class_eval do
    # Reference PR https://github.com/decidim/decidim/pull/14968
    def resource_image_path
      return has_image?
    end

    def has_image?
      model.attachments.presence&.find_by("content_type LIKE ?", "image/%")&.url
    end
  end
end