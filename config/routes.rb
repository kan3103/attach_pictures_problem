Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  namespace :api do
    namespace :v1 do
      namespace :upload_image do
        post 'upload_zip', to: 'unzip#upload_zip'
      end
    end
  end
end
