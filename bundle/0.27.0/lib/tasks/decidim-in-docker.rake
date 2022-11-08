namespace :decidim do
  desc "Create an organization and admin if doesn't exists"
  task seed: :environment do |t, args|
    # Check if there are some migrations pending
    if Base.connection.migration_context.needs_migration?
      `bundle exec rails db:migrate`
    end
    # Raise a pending migration error if some migrations don't worked
    raise ActiveRecord::PendingMigrationError if Base.connection.migration_context.needs_migration?

    # Do not seed if DECIDIM_SEED env is not "1" or if an organization already exists
    return if ENV.fetch("DECIDIM_SEED", "0") != "1"
    return if ::Decidim::Organization.count > 0
    
    # Create an admin for `/system`
    ::Decidim::System::Admin.create!(
      email: "admin@example.org",
      password: "123456",
      password_confirmation: "123456",
    )

    # Create an Organization for `0.0.0.0:3000`
    organization = ::Decidim::Organization.create!(
      host: "0.0.0.0",
      secondary_hosts: ["127.0.0.1", "localhost"],
      name: ENV.fetch("DECIDIM_APPLICATION_NAME", "My application"),
      default_locale: ENV.fetch("DECIDIM_DEFAULT_LOCALE", "en").to_sym,
      available_locales: ENV.fetch("DECIDIM_AVAILABLE_LOCALES", "ca,cs,de,en,es,eu,fi,fr,it,ja,nl,pl,pt,ro").split(",").map(&:strip).map(&:to_sym),
      reference_prefix: "REF",
      available_authorizations: [],
      users_registration_mode: :enabled,
      tos_version: Time.current,
      badges_enabled: true,
      user_groups_enabled: true,
      send_welcome_notification: true,
      file_upload_settings: ::Decidim::OrganizationSettings.default(:upload)
    )

    # Create default pages
    ::Decidim::System::CreateDefaultPages.call(organization)
    ::Decidim::System::PopulateHelp.call(organization)
    ::Decidim::System::CreateDefaultContentBlocks.call(organization)

    # Create an admin for `/admin`
    user = ::Decidim::User.create!(
      email: "admin@example.org",
      name: "admin",
      nickname: "admin",
      password: "123456",
      password_confirmation: "123456",
      organization: organization,
      confirmed_at: Time.current,
      locale: organization.default_locale,
      admin: true,
      tos_agreement: true,
      personal_url: "",
      about: "",
      accepted_tos_version: organization.tos_version,
      admin_terms_accepted_at: Time.current
    )
  end
end
