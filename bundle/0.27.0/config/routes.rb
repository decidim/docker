Rails.application.routes.draw do
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  mount Decidim::Core::Engine => '/'
  authenticate(:admin) do
    mount Sidekiq::Web => '/_queuedjobs'
  end

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
